//
//  OverviewCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import Foundation
import Moya
import MBProgressHUD
import WalletConnectSwift
import KrystalWallets
import UIKit
import AppState
import Dependencies

protocol OverviewCoordinatorDelegate: class {
  func overviewCoordinatorDidImportWallet(wallet: KWallet, chainType: ChainType)
  func overviewCoordinatorOpenCreateChainWalletMenu(chainType: ChainType)
  func overviewCoordinatorDidSelectAddWallet()
  func overviewCoordinatorDidSelectManageWallet()
  func overviewCoordinatorDidSelectSwapToken(token: Token, isBuy: Bool)
  func overviewCoordinatorDidSelectDepositMore(tokenAddress: String)
  func overviewCoordinatorDidSelectAddToken(_ token: TokenObject)
  func overviewCoordinatorDidStart()
  func overviewCoordinatorDidPullToRefresh(mode: ViewMode, overviewMode: OverviewMode)
  func overviewCoordinatorBuyCrypto()
  func overviewCoordinatorDidSelectAllChain()
  func overviewCoordinatorOpenPromotion(code: String)
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
  var historyCoordinator: KNHistoryCoordinator?
  var withdrawCoordinator: WithdrawCoordinator?
  var krytalCoordinator: KrytalCoordinator?
  var notificationsCoordinator: NotificationCoordinator?
  var importWalletCoordinator: KNImportWalletCoordinator?
  var searchRouter = AdvanceSearchTokenRouter()
  var currentCurrencyType: CurrencyMode = CurrencyMode(rawValue: UserDefaults.standard.integer(forKey: Constants.currentCurrencyMode)) ?? .usd

  lazy var rootViewController: OverviewMainViewController = {
    let viewModel = OverviewMainViewModel()
    let viewController = OverviewMainViewController(viewModel: viewModel)
    viewController.delegate = self
    return viewController
  }()
  
  lazy var browsingRootViewController: OverviewBrowsingViewController = {
    let viewModel = OverviewBrowsingViewModel()
    let viewController = OverviewBrowsingViewController(viewModel: viewModel)
    viewController.delegate = self
    return viewController
  }()

  lazy var depositViewController: OverviewDepositViewController = {
    let controller = OverviewDepositViewController()
    controller.delegate = self
    return controller
  }()
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }

  weak var delegate: OverviewCoordinatorDelegate?
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    if KNGeneralProvider.shared.isBrowsingMode {
      self.navigationController.viewControllers = [self.browsingRootViewController]
    } else {
      self.navigationController.viewControllers = [self.rootViewController]
    }
    
    self.observeAppEvents()
  }
  
  func stop() {
    self.removeObservers()
  }
  
  func appCoordinatorReceivedTokensDetailFromUniversalLink(tokenAddress: String?, chainIdString: String?) {
      guard let chainIdString = chainIdString, let tokenAddress = tokenAddress else {
          return
      }
      let chainID = Int(chainIdString) ?? KNGeneralProvider.shared.currentChain.getChainId()
      AppDependencies.router.openToken(navigationController: navigationController, address: tokenAddress, chainID: chainID)
  }

  func openChartView(token: Token, chainId: Int? = nil, animated: Bool = true) {
      guard let chainID = chainId else { return }
      Tracker.track(event: .marketOpenDetail)
      AppDependencies.router.openToken(navigationController: navigationController, address: token.address, chainID: chainID)
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
    self.sendCoordinator?.coordinatorAppSwitchAddress()
    self.historyCoordinator?.appDidSwitchAddress()
    self.krytalCoordinator?.coordinatorAppSwitchAddress()
    self.searchRouter.appCoordinatorDidUpdateNewSession()
  }
  
  //TODO: coordinator update balance, coordinator change wallet
  func appCoordinatorDidUpdateTokenList() {
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
    self.browsingRootViewController.reloadUI()
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
    self.sendCoordinator?.appCoordinatorDidUpdateChain()
  }

  func appCoordinatorReceiveWallectConnectURI(_ uri: String) {
    if self.navigationController.tabBarController?.selectedIndex != 0 {
      self.navigationController.tabBarController?.selectedIndex = 0
    }
    AppEventCenter.shared.didScanWalletConnect(address: currentAddress, url: uri)
  }

  func appCoordinatorPullToRefreshDone() {
    self.rootViewController.coordinatorPullToRefreshDone()
  }

  func openQRCodeScreen() {
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(navigationController: self.navigationController)
    qrcodeCoordinator.start()
    self.qrCodeCoordinator = qrcodeCoordinator
  }
    
    func openApprovalTokens() {
        let coordinator = ApprovalsCoordinator(navigationController: navigationController)
        coordinator.onCompleted = { [weak self] in
            self?.removeCoordinator(coordinator)
        }
        coordinate(coordinator: coordinator)
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
  
  func openAddChainWalletMenu(chain: ChainType) {
    let coordinator = CreateChainWalletMenuCoordinator(parentViewController: navigationController, chainType: chain, delegate: self)
    coordinator.onCompleted = { [weak self] in
      self?.coordinate(coordinator: coordinator)
    }
    coordinate(coordinator: coordinator)
  }
    
    func openSendTokenView(_ token: Token?, recipientAddress: String = "") {
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
            from: from,
            recipientAddress: recipientAddress
        )
        coordinator.delegate = self
        coordinator.start()
        self.sendCoordinator = coordinator
    }

}

extension OverviewCoordinator: CreateChainWalletMenuCoordinatorDelegate { }

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

  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.overviewCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
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

extension OverviewCoordinator: OverviewBrowsingViewControllerDelegate {
  func didSelectToken(_ controller: OverviewBrowsingViewController, token: Token) {
    MixPanelManager.track("token_detail_open", properties: ["screenid": "token_detail"])
    self.openChartView(token: token, chainId: nil)
  }
  
  func didSelectSearch(_ controller: OverviewBrowsingViewController) {
    let module = searchRouter.createModule(currencyMode: self.currentCurrencyType, coordinator: self)
    navigationController.pushViewController(module, animated: true)
  }

  func didSelectNotification(_ controller: OverviewBrowsingViewController) {
    let coordinator = NotificationCoordinator(navigationController: self.navigationController)
    coordinator.start()
    self.notificationsCoordinator = coordinator
  }
}

extension OverviewCoordinator: OverviewMainViewControllerDelegate {
  
  func changeMode(mode: ViewMode, controller: OverviewMainViewController) {
    let actionController = KrystalActionSheetController()
    
    actionController.headerData = "Tokens Data"
    let supplyType = mode == .supply ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Supply", image: UIImage(named: "supply_actionsheet_icon")!), style: supplyType, handler: { _ in
      controller.coordinatorDidSelectMode(.supply)
      MixPanelManager.track("token_data_show_supply", properties: ["screenid": "token_data_pop_up"])
    }))
    
    let assetType = mode == .asset(rightMode: .value) ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Asset", image: UIImage(named: "asset_actionsheet_icon")!), style: assetType, handler: { _ in
      controller.coordinatorDidSelectMode(.asset(rightMode: .value))
      MixPanelManager.track("token_data_show_asset", properties: ["screenid": "token_data_pop_up"])
    }))
      
    let showLPType = mode == .showLiquidityPool ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Liquidity Pool Tokens", image: UIImage(named: "show_LP_icon")!), style: showLPType, handler: { _ in
      controller.coordinatorDidSelectMode(.showLiquidityPool)
      MixPanelManager.track("token_data_show_liquidity_pool", properties: ["screenid": "token_data_pop_up"])
    }))
      
    let nftType = mode == .nft ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show NFT", image: UIImage(named: "nft_actionsheet_icon")!), style: nftType, handler: { _ in
      controller.coordinatorDidSelectMode(.nft)
      MixPanelManager.track("token_data_show_nft", properties: ["screenid": "token_data_pop_up"])
    }))
    let marketType = mode == .market(rightMode: .ch24) ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Show Market", image: UIImage(named: "market_actionsheet_icon")!), style: marketType, handler: { _ in
      controller.coordinatorDidSelectMode(.market(rightMode: .ch24))
      MixPanelManager.track("token_data_show_market", properties: ["screenid": "token_data_pop_up"])
    }))
    let favType = mode == .favourite(rightMode: .ch24) ? ActionStyle.selected : ActionStyle.default
    actionController.addAction(Action(ActionData(title: "Favorites", image: UIImage(named: "favorites_actionsheet_icon")!), style: favType, handler: { _ in
      controller.coordinatorDidSelectMode(.favourite(rightMode: .ch24))
      MixPanelManager.track("token_data_show_favorites", properties: ["screenid": "token_data_pop_up"])
    }))
    self.navigationController.present(actionController, animated: true, completion: nil)
    MixPanelManager.track("token_data_pop_up_open", properties: ["screenid": "token_data_pop_up"])
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
      if self.currentAddress.isWatchWallet {
        let coordinator = AddWatchWalletCoordinator(parentViewController: self.navigationController, editingAddress: self.currentAddress)
        coordinator.onCompleted = { [weak self] in
          self?.removeCoordinator(coordinator)
        }
        self.coordinate(coordinator: coordinator)
      } else {
        guard let wallet = WalletManager.shared.getWallet(id: self.currentAddress.walletID) else {
          return
        }
        let coordinator = EditWalletCoordinator(
          navigationController: self.navigationController,
          wallet: wallet,
          addressType: KNGeneralProvider.shared.currentChain.addressType
        )
        coordinator.onCompleted = { [weak self] _ in
          self?.removeCoordinator(coordinator)
        }
        self.coordinate(coordinator: coordinator)
      }
    }))
    actionController.addAction(Action(ActionData(title: "Show History", image: UIImage(named: "history_actionsheet_icon")!), style: .default, handler: { _ in
      self.openHistoryScreen()
    }))
      
      if FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.tokenApproval) && !KNGeneralProvider.shared.isBrowsingMode {
          actionController.addAction(Action(ActionData(title: Strings.approvalMenuTitle, image: Images.exploreApprovalIcon), style: .default, handler: { [weak self] _ in
            self?.openApprovalTokens()
          }))
      }

    if !currentAddress.isWatchWallet {
      actionController.addAction(Action(ActionData(title: "Export Wallet", image: UIImage(named: "export_actionsheet_icon")!), style: .default, handler: { _ in
        guard let wallet = WalletManager.shared.getWallet(id: self.currentAddress.walletID) else {
          return
        }
        let coordinator = ExportWalletCoordinator(
          navigationController: self.navigationController,
          wallet: wallet,
          addressType: KNGeneralProvider.shared.currentChain.addressType
        )
        coordinator.coordinate(coordinator: coordinator)
      }))
    }
    actionController.addAction(Action(ActionData(title: "DELETE", image: UIImage(named: "delete_actionsheet_icon")!), style: .destructive, handler: { _ in
      guard let wallet = WalletManager.shared.getWallet(id: self.currentAddress.walletID) else {
        return
      }
      let coordinator = DeleteWalletCoordinator(navigationController: self.navigationController, wallet: wallet)
      coordinator.onCompleted = { [weak self] in
        self?.removeCoordinator(coordinator)
      }
      self.coordinate(coordinator: coordinator)
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
    case .select(token: let token, chainId: let chainId):
      MixPanelManager.track("token_detail_open", properties: ["screenid": "token_detail"])
      self.openChartView(token: token, chainId: chainId)
    case .selectListWallet:
      let walletsList = WalletListV2ViewController()
      let navigation = UINavigationController(rootViewController: walletsList)
      navigation.setNavigationBarHidden(true, animated: false)
      MixPanelManager.track("wallet_popup_open", properties: ["screenid": "wallet_popup"])
    case .send(let recipientAddress):
      self.openSendTokenView(nil, recipientAddress: recipientAddress ?? "")
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
            Tracker.track(event: .marketSwitch24h)
            controller.coordinatorDidSelectMode(.market(rightMode: .ch24))
          default:
            Tracker.track(event: .marketSwitchCap)
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
          MixPanelManager.track("display_data_last_price", properties: ["screenid": "token_data_pop_up"])
        }))
        let ch24Type = mode == .ch24 ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Percentage Change", image: UIImage(named: "24ch_actionsheet_icon")!), style: ch24Type, handler: { _ in
          controller.coordinatorDidSelectMode(.market(rightMode: .ch24))
          MixPanelManager.track("display_data_percentage_change", properties: ["screenid": "token_data_pop_up"])
        }))
      case .favourite(rightMode: let mode):
        let priceType = mode == .lastPrice ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Last Price", image: UIImage(named: "price_actionsheet_icon")!), style: priceType, handler: { _ in
          controller.coordinatorDidSelectMode(.favourite(rightMode: .lastPrice))
          MixPanelManager.track("display_data_last_price", properties: ["screenid": "token_data_pop_up"])
        }))
        let ch24Type = mode == .ch24 ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Percentage Change", image: UIImage(named: "24ch_actionsheet_icon")!), style: ch24Type, handler: { _ in
          controller.coordinatorDidSelectMode(.favourite(rightMode: .ch24))
          MixPanelManager.track("display_data_percentage_change", properties: ["screenid": "token_data_pop_up"])
        }))
      case .asset(rightMode: let mode):
        let priceType = mode == .lastPrice ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Last Price", image: UIImage(named: "price_actionsheet_icon")!), style: priceType, handler: { _ in
          controller.coordinatorDidSelectMode(.asset(rightMode: .lastPrice))
          MixPanelManager.track("display_data_last_price", properties: ["screenid": "token_data_pop_up"])
        }))
        let valueType = mode == .value ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Value", image: UIImage(named: "value_actionsheet_icon")!), style: valueType, handler: { _ in
          controller.coordinatorDidSelectMode(.asset(rightMode: .value))
          MixPanelManager.track("display_data_value", properties: ["screenid": "token_data_pop_up"])
        }))
        let ch24Type = mode == .ch24 ? ActionStyle.selected : ActionStyle.default
        actionController.addAction(Action(ActionData(title: "Percentage Change", image: UIImage(named: "24ch_actionsheet_icon")!), style: ch24Type, handler: { _ in
          controller.coordinatorDidSelectMode(.asset(rightMode: .ch24))
          MixPanelManager.track("display_data_percentage_change", properties: ["screenid": "token_data_pop_up"])
        }))
      default:
        break
      }
      self.navigationController.present(actionController, animated: true, completion: nil)
      MixPanelManager.track("display_data_pop_up_open", properties: ["screenid": "display_data_pop_up"])
    case .addNFT:
      let vc = OverviewAddNFTViewController()
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: true)
      MixPanelManager.track("add_nft_open", properties: ["screenid": "add_nft"])
    case .openNFTDetail(item: let item, category: let category):
      let viewModel = OverviewNFTDetailViewModel(item: item, category: category)
      let vc = OverviewNFTDetailViewController(viewModel: viewModel)
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: true)
      MixPanelManager.track("nft_detail_open", properties: ["screenid": "nft_detail"])
    case .didAppear:
      self.delegate?.overviewCoordinatorDidStart()
    case .buyCrypto:
      self.delegate?.overviewCoordinatorBuyCrypto()
    case .addNewWallet:
      self.delegate?.overviewCoordinatorDidSelectAddWallet()
    case .addChainWallet(let chain):
      self.delegate?.overviewCoordinatorOpenCreateChainWalletMenu(chainType: chain)
    case .scannedWalletConnect(let url):
      AppEventCenter.shared.didScanWalletConnect(address: currentAddress, url: url)
    case .selectAllChain:
      self.delegate?.overviewCoordinatorDidSelectAllChain()
      self.loadMultichainAssetsData { chainBalanceModels in
        self.rootViewController.coordinatorDidUpdateAllTokenData(models: chainBalanceModels)
      }
    case .importWallet(let privateKey, let chain):
      let coordinator = KNImportWalletCoordinator(navigationController: navigationController)
      self.importWalletCoordinator = coordinator
      coordinator.startImportFlow(privateKey: privateKey, chain: chain)
    case .openPromotion(let code):
      delegate?.overviewCoordinatorOpenPromotion(code: code)
    case .getBadgeNotification:
      let service = NotificationService()
      service.getNotificationBadgeNumber(userAddress: self.currentAddress.addressString) { number in
        self.rootViewController.coordinatorDidUpdateNotificationBadgeNumber(number: number)
      }
    }
  }
}

extension OverviewCoordinator {

  func loadMultichainAssetsData(completion: @escaping ([ChainBalanceModel]) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let allChainIds = ChainType.getAllChain().map {
      return "\($0.getChainId())"
    }
    let addressesString = AppDelegate.session.getCurrentWalletAddresses().map { address -> String in
      if address.addressType == .evm {
        return "ethereum:\(address.addressString)"
      } else {
        return "solana:\(address.addressString)"
      }
    }
    var quoteSymbols = ["btc,usd"]
    
    provider.requestWithFilter(.getMultichainBalance(address: addressesString, chainIds: allChainIds, quoteSymbols: quoteSymbols)) { (result) in
      switch result {
      case .success(let resp):
        var chainBalanceModels: [ChainBalanceModel] = []
        if let responseJson = try? resp.mapJSON() as? JSONDictionary ?? [:], let jsons = responseJson["data"] as? [JSONDictionary] {
          jsons.forEach { jsonData in
            let model = ChainBalanceModel(json: jsonData)
            chainBalanceModels.append(model)
          }
        }
        completion(chainBalanceModels)
      case .failure(let error):
        self.showWarningTopBannerMessage(
          with: "",
          message: error.localizedDescription,
          time: 2.0
        )
        completion([])
      }
    }
  }
  
}

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
                      nftCategory.chainType = KNGeneralProvider.shared.currentChain
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
                      nftCategory.chainType = KNGeneralProvider.shared.currentChain
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
          let signedData = try EthSigner().signMessageHash(address: currentAddress, data: sendData, addPrefix: false)
          print("[Send favorite nft] success")
          let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
          provider.requestWithFilter(.registerNFTFavorite(address: currentAddress.addressString, collectibleAddress: category.collectibleAddress, tokenID: item.tokenID, favorite: status, signature: signedData.hexEncoded, chain: category.chainType ?? KNGeneralProvider.shared.currentChain)) { result in
            if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
              if let isSuccess = json["success"] as? Bool, isSuccess {
                self.navigationController.showTopBannerView(message: (status ? "Successful added to your favorites" : "Removed from your favorites" ))
                controller.coordinatorDidUpdateFavStatus(status)
                AppDelegate.shared.coordinator.loadBalanceCoordinator?.loadNFTBalance(completion: { _ in })
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
