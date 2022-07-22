//
//  OverviewCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import Foundation
import Moya
import QRCodeReaderViewController
import MBProgressHUD
import WalletConnectSwift
import KrystalWallets

protocol OverviewCoordinatorDelegate: class {
  func overviewCoordinatorOpenCreateChainWalletMenu(chainType: ChainType)
  func overviewCoordinatorDidSelectAddWallet()
  func overviewCoordinatorDidSelectManageWallet()
  func overviewCoordinatorDidSelectSwapToken(token: Token, isBuy: Bool)
  func overviewCoordinatorDidSelectDepositMore(tokenAddress: String)
  func overviewCoordinatorDidSelectAddToken(_ token: TokenObject)
  func overviewCoordinatorDidChangeHideBalanceStatus(_ status: Bool)
  func overviewCoordinatorDidSelectRenameWallet()
  func overviewCoordinatorDidSelectExportWallet()
  func overviewCoordinatorDidSelectDeleteWallet()
  func overviewCoordinatorDidStart()
  func overviewCoordinatorDidPullToRefresh(mode: ViewMode, overviewMode: OverviewMode)
  func overviewCoordinatorBuyCrypto()
}

class PoolPairToken: Codable {
  var address: String
  var name: String
  var symbol: String
  var logo: String
  var tvl: Double
  var decimals: Int
  var usdValue: Double

  init(json: JSONDictionary) {
    self.address = json["id"] as? String ?? ""
    self.name = json["name"] as? String ?? ""
    self.symbol = json["symbol"] as? String ?? ""
    self.decimals = json["decimals"] as? Int ?? 0
    self.logo = json["logo"] as? String ?? ""
    self.tvl = json["tvl"] as? Double ?? 0.0
    self.usdValue = json["usdValue"] as? Double ?? 0.0
  }
}

class TokenPoolDetail: Codable {
  var address: String
  var tvl: Double
  var chainId: Int
  var name: String
  
  var token0: PoolPairToken
  var token1: PoolPairToken
  
  init(json: JSONDictionary) {
    self.address = json["address"] as? String ?? ""
    self.tvl = json["tvl"] as? Double ?? 0.0
    self.chainId = json["chainId"] as? Int ?? 0
    self.name = json["name"] as? String ?? ""
    self.token0 = PoolPairToken(json: json["token0"] as? JSONDictionary ?? JSONDictionary())
    self.token1 = PoolPairToken(json: json["token1"] as? JSONDictionary ?? JSONDictionary())
  }
}

class OverviewCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]
  var sendCoordinator: KNSendTokenViewCoordinator?
  var qrCodeCoordinator: KNWalletQRCodeCoordinator?
  var addTokenCoordinator: AddTokenCoordinator?
  var historyCoordinator: KNHistoryCoordinator?
  var withdrawCoordinator: WithdrawCoordinator?
  var krytalCoordinator: KrytalCoordinator?
  var notificationsCoordinator: NotificationCoordinator?
  var searchRouter = AdvanceSearchTokenRouter()
  var currentCurrencyType: CurrencyMode = CurrencyMode(rawValue: UserDefaults.standard.integer(forKey: Constants.currentCurrencyMode)) ?? .usd
  var pendingAction: (() -> Void)?

  lazy var rootViewController: OverviewMainViewController = {
    let viewModel = OverviewMainViewModel()
    let viewController = OverviewMainViewController(viewModel: viewModel)
    viewController.delegate = self
    return viewController
  }()

  lazy var depositViewController: OverviewDepositViewController = {
    let controller = OverviewDepositViewController()
    controller.delegate = self
    return controller
  }()
  
//  fileprivate var currentWallet: KNWalletObject {
//    return self.session.currentWalletObject
//  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }

  weak var delegate: OverviewCoordinatorDelegate?
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.observeAppEvents()
  }
  
  func stop() {
    self.removeObservers()
  }
  
  func appCoordinatorReceivedTokensDetailFromUniversalLink(tokenAddress: String?, chainIdString: String?) {
    guard let chainIdString = chainIdString, let tokenAddress = tokenAddress else {
      return
    }
    let chainId = Int(chainIdString) ?? KNGeneralProvider.shared.currentChain.getChainId()
    let tokenModel = Token(name: "", symbol: "", address: tokenAddress, decimals: 18, logo: "")
    let viewModel = ChartViewModel(token: tokenModel, currencyMode: .usd)
    viewModel.chainId = chainId
    let controller = ChartViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }

  fileprivate func openChartView(token: Token) {
    KNCrashlyticsUtil.logCustomEvent(withName: "market_open_detail", customAttributes: nil)
    let viewModel = ChartViewModel(token: token, currencyMode: self.currentCurrencyType)
    let controller = ChartViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  fileprivate func openKrytalView() {
    let coordinator = KrytalCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
    coordinator.start()
    self.krytalCoordinator = coordinator
  }
  
  func removeObservers() {
    NotificationCenter.default.removeObserver(
      self,
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  func observeAppEvents() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidSwitchAddress),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  @objc func appDidSwitchAddress() {
    self.rootViewController.coordinatorAppSwitchAddress()
    self.sendCoordinator?.coordinatorAppSwitchAddress()
    self.historyCoordinator?.appDidSwitchAddress()
    self.krytalCoordinator?.coordinatorAppSwitchAddress()
    self.searchRouter.appCoordinatorDidUpdateNewSession()
    if let pendingAction = pendingAction {
      pendingAction()
    }
  }
  
  //TODO: coordinator update balance, coordinator change wallet
  func appCoordinatorDidUpdateTokenList() {
    self.rootViewController.coordinatorDidUpdateDidUpdateTokenList()
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }
  
  func appCoordinatorPendingTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate()
    self.sendCoordinator?.coordinatorDidUpdatePendingTx()
    self.withdrawCoordinator?.coordinatorDidUpdatePendingTx()
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }
  
  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if self.sendCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    return self.withdrawCoordinator?.appCoordinatorUpdateTransaction(tx) ?? false
  }
  
  func appCoordinatorDidUpdateChain() {
    if self.currentCurrencyType.isQuoteCurrency {
      self.currentCurrencyType = KNGeneralProvider.shared.quoteCurrency
    }
    UserDefaults.standard.setValue(self.currentCurrencyType.rawValue, forKey: Constants.currentCurrencyMode)
    self.rootViewController.coordinatorDidUpdateChain()
    self.sendCoordinator?.appCoordinatorDidUpdateChain()
  }

  func appCoordinatorReceiveWallectConnectURI(_ uri: String) {
    if self.navigationController.tabBarController?.selectedIndex != 0 {
      self.navigationController.tabBarController?.selectedIndex = 0
    }
    self.handleWalletConnectURI(uri, disconnectAfterDisappear: false)
  }

  func appCoordinatorPullToRefreshDone() {
    self.rootViewController.coordinatorPullToRefreshDone()
  }

  func openQRCodeScreen() {
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(navigationController: self.navigationController)
    qrcodeCoordinator.start()
    self.qrCodeCoordinator = qrcodeCoordinator
  }
  
  func openAddTokenScreen() {
    let tokenCoordinator = AddTokenCoordinator(navigationController: self.navigationController)
    tokenCoordinator.start()
    self.addTokenCoordinator = tokenCoordinator
  }
  
  func openHistoryScreen() {
    switch KNGeneralProvider.shared.currentChain {
    case .solana:
      let coordinator = KNTransactionHistoryCoordinator(navigationController: navigationController, type: .solana)
      coordinator.delegate = self
      coordinate(coordinator: coordinator)
    default:
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(
        navigationController: self.navigationController
      )
      self.historyCoordinator?.delegate = self
      self.historyCoordinator?.appDidSwitchAddress()
      self.historyCoordinator?.start()
    }
  }
}

extension OverviewCoordinator: ChartViewControllerDelegate {
  func chartViewController(_ controller: ChartViewController, run event: ChartViewEvent) {
    switch event {
    case .getPoolList(address: let address, chainId: let chainId):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.requestWithFilter(.getPoolList(tokenAddress: address, chainId: chainId, limit: 50)) { result in
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          var allPools: [TokenPoolDetail] = []
          if let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let jsonData = json["data"] as? [JSONDictionary] {
            jsonData.forEach { poolJson in
              let tokenPoolDetail = TokenPoolDetail(json: poolJson)
              if !tokenPoolDetail.token0.symbol.isEmpty && !tokenPoolDetail.token1.symbol.isEmpty {
                allPools.append(tokenPoolDetail)
              }
            }
          }
          controller.coordinatorDidUpdatePoolData(poolData: allPools)
        }
      }
    case .getChartData(let address, let from, let to, let currency):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      var chainPath = KNGeneralProvider.shared.chainPath
      if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
        chainPath = chainType.chainPath()
      }
      self.navigationController.showLoadingHUD()
      provider.requestWithFilter(.getChartData(chainPath: chainPath, address: address, quote: currency, from: from)) { result in
        DispatchQueue.main.async {
          self.navigationController.hideLoading()
        }
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(ChartDataResponse.self, from: resp.data)
            controller.coordinatorDidUpdateChartData(data.prices)
          } catch let error {
            print("[Debug]" + error.localizedDescription)
          }
        }
      }
    case .getTokenDetailInfo(address: let address):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      var chainPath = KNGeneralProvider.shared.chainPath
      if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
        chainPath = chainType.chainPath()
      }
      self.navigationController.showLoadingHUD()
      provider.requestWithFilter(.getTokenDetail(chainPath: chainPath, address: address)) { (result) in
        DispatchQueue.main.async {
          self.navigationController.hideLoading()
        }
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(TokenDetailResponse.self, from: resp.data)
            controller.coordinatorDidUpdateTokenDetailInfo(data.result)
          } catch let error {
            print("[Debug]" + error.localizedDescription)
            controller.coordinatorDidUpdateTokenDetailInfo(nil)
          }
        }
      }
    case .transfer(token: let token):
      var chainPath = KNGeneralProvider.shared.chainPath
      if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
        chainPath = chainType.chainPath()
      }
      if chainPath != KNGeneralProvider.shared.chainPath {
        let alertController = KNPrettyAlertController(
          title: "",
          message: Strings.pleaseSwitchTo + " \(chainPath.dropFirst().uppercased()) " + Strings.toSwap,
          secondButtonTitle: Strings.OK,
          firstButtonTitle: Strings.Cancel,
          secondButtonAction: {
            self.handleSwitchChain(controller) {
              self.openSendTokenView(token)
              self.pendingAction = nil
            }
          },
          firstButtonAction: nil
        )
        alertController.popupHeight = 300
        self.navigationController.present(alertController, animated: true, completion: nil)
      } else {
        self.openSendTokenView(token)
      }
      
    case .swap(token: let token):
      var chainPath = KNGeneralProvider.shared.chainPath
      if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
        chainPath = chainType.chainPath()
      }
      if chainPath != KNGeneralProvider.shared.chainPath {
        let alertController = KNPrettyAlertController(
          title: "",
          message: Strings.pleaseSwitchTo + " \(chainPath.dropFirst().uppercased()) " + Strings.toSwap,
          secondButtonTitle: Strings.OK,
          firstButtonTitle: Strings.Cancel,
          secondButtonAction: {
            self.handleSwitchChain(controller) {
              self.openSwapView(token: token, isBuy: true)
              self.pendingAction = nil
            }
          },
          firstButtonAction: nil
        )
        alertController.popupHeight = 300
        self.navigationController.present(alertController, animated: true, completion: nil)
      } else {
        self.openSwapView(token: token, isBuy: true)
      }
    case .invest(token: let token):
      self.delegate?.overviewCoordinatorDidSelectDepositMore(tokenAddress: token.address)
    case .openEtherscan(let address, let chain):
      self.openCommunityURL("\(chain.customRPC().etherScanEndpoint)address/\(address)")
    case .openWebsite(url: let url):
      self.openCommunityURL(url)
    case .openTwitter(name: let name):
      self.openCommunityURL("https://twitter.com/\(name)/")
    case .selectPool(source: let source, quote: let quote):
      break
    case .openDiscord(link: let link):
      self.navigationController.openSafari(with: link)
    case .openTelegram(link: let link):
      self.navigationController.openSafari(with: link)
    }
  }
  
  func handleSwitchChain(_ controller: ChartViewController, completion: @escaping () -> Void) {
    self.pendingAction = nil
    var newChain = KNGeneralProvider.shared.currentChain
    if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
      newChain = chainType
    }
    if KNWalletStorage.shared.getAvailableWalletForChain(newChain).isEmpty {
      self.delegate?.overviewCoordinatorOpenCreateChainWalletMenu(chainType: newChain)
      self.pendingAction = completion
      return
    }
    let viewModel = SwitchChainWalletsListViewModel(selected: newChain)
    let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
    self.navigationController.present(secondPopup, animated: true, completion: nil)
    self.pendingAction = completion
  }

  func openCommunityURL(_ url: String) {
    self.navigationController.openSafari(with: url)
  }

  func openSendTokenView(_ token: Token?) {
    let from: TokenObject = {
      if let fromToken = token {
        if let fromTokenObject = KNSupportedTokenStorage.shared.supportedToken.first { $0.address == fromToken.address }?.toObject() {
          return fromTokenObject
        }
        return fromToken.toObject()
      }
      return KNGeneralProvider.shared.quoteTokenObject
    }()
    self.sendCoordinator = nil
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      balances: self.balances,
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }

  func openSwapView(token: Token, isBuy: Bool) {
    self.delegate?.overviewCoordinatorDidSelectSwapToken(token: token, isBuy: isBuy)
  }
}

extension OverviewCoordinator: NavigationBarDelegate {
  func viewControllerDidSelectHistory(_ controller: KNBaseViewController) {
    self.openHistoryScreen()
  }

  func viewControllerDidSelectWallets(_ controller: KNBaseViewController) {
    let actionController = KrystalActionSheetController()
    
    actionController.headerData = "Tokens Data"
    actionController.addAction(Action(ActionData(title: "Add to Watch Later", image: UIImage(named: "knc")!), style: .default, handler: { action in
    }))
    actionController.addAction(Action(ActionData(title: "Add to Playlist...", image: UIImage(named: "knc")!), style: .default, handler: { action in
    }))
    actionController.addAction(Action(ActionData(title: "Share...", image: UIImage(named: "knc")!), style: .default, handler: { action in
    }))
    actionController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "knc")!), style: .destructive, handler: nil))
    
    self.navigationController.present(actionController, animated: true, completion: nil)
    
    
  }
}

extension OverviewCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.overviewCoordinatorDidSelectManageWallet()
    case .didSelect(let address):
      return
    case .addWallet:
      self.delegate?.overviewCoordinatorDidSelectAddWallet()
    }
  }
}

extension OverviewCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.handleWalletConnectURI(result)
    }
  }
  
  func handleWalletConnectURI(_ result: String, disconnectAfterDisappear: Bool = true) {
    guard let url = WCURL(result) else {
      self.navigationController.showTopBannerView(
        with: Strings.invalidSession,
        message: Strings.invalidSessionTryOtherQR,
        time: 1.5
      )
      return
    }

    do {
      let privateKey = try WalletManager.shared.exportPrivateKey(address: AppDelegate.session.address)
      DispatchQueue.main.async {
        let controller = KNWalletConnectViewController(
          wcURL: url,
          pk: privateKey
        )
        self.navigationController.present(controller, animated: true, completion: nil)
      }
    } catch {
      self.navigationController.showTopBannerView(
        with: Strings.privateKeyError,
        message: Strings.canNotGetPrivateKey,
        time: 1.5
      )
    }
  }
}

extension OverviewCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.overviewCoordinatorOpenCreateChainWalletMenu(chainType: chainType)
  }
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.overviewCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }

  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }

  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }

}

extension OverviewCoordinator: OverviewDepositViewControllerDelegate {
  func overviewDepositViewController(_ controller: OverviewDepositViewController, run event: OverviewDepositViewEvent) {
    switch event {
    case .withdrawBalance(platform: let platform, balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController)
      coordinator.platform = platform
      coordinator.balance = balance
      coordinator.start()
      coordinator.delegate = self
      self.withdrawCoordinator = coordinator
    case .claim(balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController)
      coordinator.claimBalance = balance
      coordinator.start()
      coordinator.delegate = self
      self.withdrawCoordinator = coordinator
    case .depositMore:
      self.delegate?.overviewCoordinatorDidSelectDepositMore(tokenAddress: "")
    }
  }
}

extension OverviewCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.overviewCoordinatorOpenCreateChainWalletMenu(chainType: chainType)
  }
  
  func sendTokenCoordinatorDidClose() {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.overviewCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
  }

  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }
}

extension OverviewCoordinator: WithdrawCoordinatorDelegate {
  func withdrawCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.overviewCoordinatorOpenCreateChainWalletMenu(chainType: chainType)
  }
  
  func withdrawCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.overviewCoordinatorDidSelectAddToken(token)
  }
  
  func withdrawCoordinatorDidSelectEarnMore(balance: LendingBalance) {
    self.delegate?.overviewCoordinatorDidSelectDepositMore(tokenAddress: balance.address)
  }
  
  func withdrawCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }
  
  func withdrawCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }
  
  func withdrawCoordinatorDidSelectHistory() {
    self.openHistoryScreen()
  }
}

extension OverviewCoordinator: KrytalCoordinatorDelegate {
  func krytalCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }
  
  func krytalCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }
}

extension OverviewCoordinator: OverviewMainViewControllerDelegate {
  
  func changeMode(mode: ViewMode, controller: OverviewMainViewController) {
    let actionController = KrystalActionSheetController()
    
    actionController.headerData = "Tokens Data"
    let supplyType = mode == .supply ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Supply", image: UIImage(named: "supply_actionsheet_icon")!), style: supplyType, handler: { _ in
      controller.coordinatorDidSelectMode(.supply)
    }))
    
    let assetType = mode == .asset(rightMode: .value) ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Asset", image: UIImage(named: "asset_actionsheet_icon")!), style: assetType, handler: { _ in
      controller.coordinatorDidSelectMode(.asset(rightMode: .value))
    }))
      
    let showLPType = mode == .showLiquidityPool ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Liquidity Pool", image: UIImage(named: "show_LP_icon")!), style: showLPType, handler: { _ in
      controller.coordinatorDidSelectMode(.showLiquidityPool)
    }))
      
    let nftType = mode == .nft ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show NFT", image: UIImage(named: "nft_actionsheet_icon")!), style: nftType, handler: { _ in
      controller.coordinatorDidSelectMode(.nft)
    }))
    let marketType = mode == .market(rightMode: .ch24) ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Market", image: UIImage(named: "market_actionsheet_icon")!), style: marketType, handler: { _ in
      controller.coordinatorDidSelectMode(.market(rightMode: .ch24))
    }))
    let favType = mode == .favourite(rightMode: .ch24) ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Favorites", image: UIImage(named: "favorites_actionsheet_icon")!), style: favType, handler: { _ in
      controller.coordinatorDidSelectMode(.favourite(rightMode: .ch24))
    }))
    self.navigationController.present(actionController, animated: true, completion: nil)
  }
  
  func configWallet(controller: OverviewMainViewController) {
    let actionController = KrystalActionSheetController()
    
    actionController.headerData = "Wallet Details"
    
    actionController.addAction(Action(ActionData(title: "Change Currency", image: UIImage(named: "currency_change_icon")!), style: .default, handler: { _ in
      let controller = OverviewChangeCurrencyViewController()
      controller.completeHandle = { mode in
        UserDefaults.standard.setValue(mode.rawValue, forKey: Constants.currentCurrencyMode)
        self.rootViewController.coordinatorDidUpdateCurrencyMode(mode)
        self.currentCurrencyType = mode
      }
      self.navigationController.present(controller, animated: true, completion: nil)
    }))
    
    actionController.addAction(Action(ActionData(title: "Copy Address", image: UIImage(named: "copy_actionsheet_icon")!), style: .default, handler: { [weak self] _ in
      guard let self = self else { return }
      UIPasteboard.general.string = self.currentAddress.addressString
      let hud = MBProgressHUD.showAdded(to: controller.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    }))
    
    actionController.addAction(Action(ActionData(title: "Share Address", image: UIImage(named: "share_actionsheet_icon")!), style: .default, handler: { [weak self] _ in
      guard let self = self else { return }
      let activityItems: [Any] = {
        var items: [Any] = []
        items.append(self.currentAddress.addressString)
        return items
      }()
      let activityViewController = UIActivityViewController(
        activityItems: activityItems,
        applicationActivities: nil
      )
      activityViewController.popoverPresentationController?.sourceView = controller.view
      controller.present(activityViewController, animated: true, completion: nil)
    }))
    actionController.addAction(Action(ActionData(title: "Rename Wallet", image: UIImage(named: "rename_actionsheet_icon")!), style: .default, handler: { _ in
      self.delegate?.overviewCoordinatorDidSelectRenameWallet()
    }))
    actionController.addAction(Action(ActionData(title: "Show History", image: UIImage(named: "history_actionsheet_icon")!), style: .default, handler: { _ in
      self.openHistoryScreen()
    }))
    actionController.addAction(Action(ActionData(title: "Export Wallet", image: UIImage(named: "export_actionsheet_icon")!), style: .default, handler: { _ in
      self.delegate?.overviewCoordinatorDidSelectExportWallet()
    }))
    actionController.addAction(Action(ActionData(title: "DELETE", image: UIImage(named: "delete_actionsheet_icon")!), style: .destructive, handler: { _ in
      self.delegate?.overviewCoordinatorDidSelectDeleteWallet()
    }))
    actionController.addAction(Action(ActionData(title: KNGeneralProvider.shared.currentChain.blockExploreName(), image: UIImage(named: "etherscan_actionsheet_icon")!), style: .default, handler: { _ in
      let url = "\(KNGeneralProvider.shared.customRPC.etherScanEndpoint)address/\(self.currentAddress.addressString)"
      self.rootViewController.openSafari(with: url)
    }))
    self.navigationController.present(actionController, animated: true, completion: nil)
  }
  
  func pullToRefresh(mode: ViewMode, overviewMode: OverviewMode) {
    self.delegate?.overviewCoordinatorDidPullToRefresh(mode: mode, overviewMode: overviewMode)
  }

  func overviewMainViewController(_ controller: OverviewMainViewController, run event: OverviewMainViewEvent) {
    switch event {
    case .pullToRefreshed(current: let mode, overviewMode: let overviewMode):
      self.pullToRefresh(mode: mode, overviewMode: overviewMode)
    case .changeMode(current: let mode):
      self.changeMode(mode: mode, controller: controller)
    case .walletConfig:
        self.configWallet(controller: controller)
    case .select(token: let token):
      self.openChartView(token: token)
    case .selectListWallet:
      let viewModel = WalletsListViewModel()
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
    case .send:
      self.openSendTokenView(nil)
    case .receive:
      self.openQRCodeScreen()
    case .notifications:
      let coordinator = NotificationCoordinator(navigationController: self.navigationController)
      coordinator.start()
      self.notificationsCoordinator = coordinator
    case .search:
      let module = searchRouter.createModule(currencyMode: self.currentCurrencyType, coordinator: self)
      navigationController.pushViewController(module, animated: true)
    case .withdrawBalance(platform: let platform, balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController)
      coordinator.platform = platform
      coordinator.balance = balance
      coordinator.start()
      coordinator.delegate = self
      self.withdrawCoordinator = coordinator
    case .claim(balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController)
      coordinator.claimBalance = balance
      coordinator.start()
      coordinator.delegate = self
      self.withdrawCoordinator = coordinator
    case .depositMore:
      self.delegate?.overviewCoordinatorDidSelectDepositMore(tokenAddress: "")
    case .changeRightMode(current: let current):
      guard current != .market(rightMode: .lastPrice) else {
        if case .market(let mode) = current {
          switch mode {
          case .lastPrice:
            KNCrashlyticsUtil.logCustomEvent(withName: "market_switch_24h", customAttributes: nil)
            controller.coordinatorDidSelectMode(.market(rightMode: .ch24))
          default:
            KNCrashlyticsUtil.logCustomEvent(withName: "market_switch_cap", customAttributes: nil)
            controller.coordinatorDidSelectMode(.market(rightMode: .lastPrice))
          }
        }
        return
      }
      
      let actionController = KrystalActionSheetController()
      actionController.headerData = "Display Data"
      
      switch current {
      case .market(rightMode: let mode):
        let priceType = mode == .lastPrice ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Last Price", image: UIImage(named: "price_actionsheet_icon")!), style: priceType, handler: { _ in
          controller.coordinatorDidSelectMode(.market(rightMode: .lastPrice))
        }))
        let ch24Type = mode == .ch24 ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Percentage Change", image: UIImage(named: "24ch_actionsheet_icon")!), style: ch24Type, handler: { _ in
          controller.coordinatorDidSelectMode(.market(rightMode: .ch24))
        }))
      case .favourite(rightMode: let mode):
        let priceType = mode == .lastPrice ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Last Price", image: UIImage(named: "price_actionsheet_icon")!), style: priceType, handler: { _ in
          controller.coordinatorDidSelectMode(.favourite(rightMode: .lastPrice))
        }))
        let ch24Type = mode == .ch24 ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Percentage Change", image: UIImage(named: "24ch_actionsheet_icon")!), style: ch24Type, handler: { _ in
          controller.coordinatorDidSelectMode(.favourite(rightMode: .ch24))
        }))
      case .asset(rightMode: let mode):
        let priceType = mode == .lastPrice ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Last Price", image: UIImage(named: "price_actionsheet_icon")!), style: priceType, handler: { _ in
          controller.coordinatorDidSelectMode(.asset(rightMode: .lastPrice))
        }))
        let valueType = mode == .value ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Value", image: UIImage(named: "value_actionsheet_icon")!), style: valueType, handler: { _ in
          controller.coordinatorDidSelectMode(.asset(rightMode: .value))
        }))
        let ch24Type = mode == .ch24 ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Percentage Change", image: UIImage(named: "24ch_actionsheet_icon")!), style: ch24Type, handler: { _ in
          controller.coordinatorDidSelectMode(.asset(rightMode: .ch24))
        }))
      default:
        break
      }
      self.navigationController.present(actionController, animated: true, completion: nil)
    case .addNFT:
      let vc = OverviewAddNFTViewController()
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: true)
    case .openNFTDetail(item: let item, category: let category):
      let viewModel = OverviewNFTDetailViewModel(item: item, category: category)
      let vc = OverviewNFTDetailViewController(viewModel: viewModel)
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: true)
    case .didAppear:
      self.delegate?.overviewCoordinatorDidStart()
    case .buyCrypto:
      self.delegate?.overviewCoordinatorBuyCrypto()
    case .addNewWallet:
      self.delegate?.overviewCoordinatorDidSelectAddWallet()
    case .addChainWallet(let chain):
      self.delegate?.overviewCoordinatorOpenCreateChainWalletMenu(chainType: chain)
      
    }
  }
}

//extension OverviewCoordinator: OverviewSearchTokenViewControllerDelegate {
//  func overviewSearchTokenViewController(_ controller: OverviewSearchTokenViewController, open token: Token) {
//    self.openChartView(token: token)
//  }
//}

extension OverviewCoordinator: OverviewAddNFTViewControllerDelegate {
  func addTokenViewController(_ controller: OverviewAddNFTViewController, run event: AddNFTViewEvent) {
    switch event {
    case .done(address: let address, id: let id):
      controller.displayLoading()
      if currentAddress.isWatchWallet {
        self.navigationController.showErrorTopBannerMessage(message: Strings.watchWalletNotSupportOperation)
        return
      }
      
      //trick fix
      KNGeneralProvider.shared.getDecimalsEncodeData { result in
      }
      
      KNGeneralProvider.shared.getSupportInterface(address: address) { interfaceResult in
        switch interfaceResult {
        case .success(let erc721):
          if erc721 {
            KNGeneralProvider.shared.getOwnerOf(address: address, id: id) { ownerResult in
              controller.hideLoading()
              switch ownerResult {
              case .success(let owner):
                if owner == self.currentAddress.addressString {
                  KNGeneralProvider.shared.getERC721Name(address: address) { nameResult in
                    switch nameResult {
                    case.success(let name):
                      let nftItem = NFTItem(name: name, tokenID: id)
                      let nftCategory = NFTSection(collectibleName: name, collectibleAddress: address, collectibleSymbol: "", collectibleLogo: "", items: [nftItem])
                      nftItem.tokenBalance = "1"
                      let msg = BalanceStorage.shared.setCustomNFT(nftCategory) ? "NFT item is saved" : "This NFT is added already"
                      self.navigationController.showTopBannerView(message: msg)
                    default:
                      break
                    }
                  }
                } else {
                  let alertController = KNPrettyAlertController(
                    title: "",
                    message: "You are not owner of this collection. So you can't add it",
                    secondButtonTitle: "Try again",
                    firstButtonTitle: "Back",
                    secondButtonAction: {
                    },
                    firstButtonAction: {
                      self.navigationController.popViewController(animated: true)
                    }
                  )
                  self.navigationController.present(alertController, animated: true, completion: nil)
                }
              case .failure(let error):
                controller.hideLoading()
                self.navigationController.showErrorTopBannerMessage(message: error.localizedDescription)
              }
            }
          } else {
            EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain).getNFTBalance(address: self.currentAddress.addressString, id: id, contract: address) { result in
              controller.hideLoading()
              switch result {
              case .success(let bigInt):
                let balance = Balance(value: bigInt)
                if balance.isZero {
                  let alertController = KNPrettyAlertController(
                    title: "",
                    message: "You are not owner of this collection. So you can't add it",
                    secondButtonTitle: "Try again",
                    firstButtonTitle: "Back",
                    secondButtonAction: {
                    },
                    firstButtonAction: {
                      self.navigationController.popViewController(animated: true)
                    }
                  )
                  self.navigationController.present(alertController, animated: true, completion: nil)
                } else {
                  KNGeneralProvider.shared.getERC721Name(address: address) { nameResult in
                    switch nameResult {
                    case.success(let name):
                      let nftItem = NFTItem(name: name, tokenID: id)
                      let nftCategory = NFTSection(collectibleName: name, collectibleAddress: address, collectibleSymbol: "", collectibleLogo: "", items: [nftItem])
                      nftItem.tokenBalance = bigInt.description
                      let msg = BalanceStorage.shared.setCustomNFT(nftCategory) ? "NFT item is saved" : "This NFT is added already"
                      self.navigationController.showTopBannerView(message: msg)
                    default:
                      break
                    }
                  }
                }
                NSLog("---- Balance: Fetch nft balance for contract \(address.description) successfully: \(bigInt.shortString(decimals: 0))")
              case .failure(let error):
                
                NSLog("---- Balance: Fetch nft balance failed with error: \(error.description). ----")
              }
            }
          }
        case .failure(let error):
          controller.hideLoading()
          self.navigationController.showErrorTopBannerMessage(message: error.localizedDescription)
        }
      }
    }
  }
}

extension OverviewCoordinator: OverviewNFTDetailViewControllerDelegate {
  fileprivate func presentSendNFTView(item: NFTItem,category: NFTSection, supportERC721: Bool) {
    self.sendCoordinator = nil
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      nftItem: item,
      supportERC721: supportERC721,
      nftCategory: category,
      sendNFT: true
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }
  
  func overviewNFTDetailViewController(_ controller: OverviewNFTDetailViewController, run event: OverviewNFTDetailEvent) {
    switch event {
    case .sendItem(item: let item, category: let category):
      
      self.navigationController.displayLoading()
      KNGeneralProvider.shared.getSupportInterface(address: category.collectibleAddress) { interfaceResult in
        self.navigationController.hideLoading()
        switch interfaceResult {
        case .success(let isERC721):
          self.presentSendNFTView(item: item, category: category, supportERC721: isERC721)
        case .failure(_):
          self.navigationController.showErrorTopBannerMessage(message: "Can not get support interface for collection")
        }
      }
    case .favoriteItem(item: let item, category: let category, status: let status):
      if currentAddress.isWatchWallet {
        self.navigationController.showErrorTopBannerMessage(message: Strings.watchWalletNotSupportOperation)
      } else {
        let data = Data(item.tokenID.utf8)
        let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
        let sendData = prefix + data
        do {
          let signedData = try EthSigner().signHash(address: currentAddress, hash: sendData)
          print("[Send favorite nft] success")
          let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
          provider.requestWithFilter(.registerNFTFavorite(address: currentAddress.addressString, collectibleAddress: category.collectibleAddress, tokenID: item.tokenID, favorite: status, signature: signedData.hexEncoded)) { result in
            if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
              if let isSuccess = json["success"] as? Bool, isSuccess {
                self.navigationController.showTopBannerView(message: (status ? "Successful added to your favorites" : "Removed from your favorites" ))
                controller.coordinatorDidUpdateFavStatus(status)
              } else if let error = json["error"] as? String {
                self.navigationController.showTopBannerView(message: error)
              } else {
                self.navigationController.showTopBannerView(message: "Fail to register favorite for \(item.externalData.name)")
              }
            }
          }
        } catch {
          print("[Send favorite nft] \(error.localizedDescription)")
        }
      }
    }
  }
}
