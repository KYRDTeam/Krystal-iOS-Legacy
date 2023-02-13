//
//  InvestCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/12/21.
//

import Foundation
import Moya
import BigInt
import WalletConnectSwift
import KrystalWallets
import BaseModule
import Dependencies
import FittedSheets
import DappBrowser

protocol InvestCoordinatorDelegate: class {
  func investCoordinatorDidSelectManageWallet()
  func investCoordinatorDidSelectAddWallet()
  func investCoordinatorDidSelectAddToken(_ token: TokenObject)
  func investCoordinatorDidSelectAddChainWallet(chainType: ChainType)
  func investCoordinator(didAdd wallet: KWallet, chain: ChainType)
  func investCoordinator(didAdd watchAddress: KAddress, chain: ChainType)
}

class InvestCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]
  var sendCoordinator: KNSendTokenViewCoordinator?
  var krytalCoordinator: KrytalCoordinator?
  var rewardCoordinator: RewardCoordinator?
  var bridgeCoordinator: BridgeCoordinator?
  var dappCoordinator: DappCoordinator?
  var buyCryptoCoordinator: BuyCryptoCoordinator?
  var rewardHuntingCoordinator: RewardHuntingCoordinator?
  var importWalletCoordinator: KNImportWalletCoordinator?
  fileprivate var loadTimer: Timer?
  weak var delegate: InvestCoordinatorDelegate?
  var historyCoordinator: KNHistoryCoordinator?
  var promoCodeCoordinator: PromoCodeCoordinator?
  
  lazy var rootViewController: InvestViewController = {
    let controller = InvestViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var multiSendCoordinator: MultiSendCoordinator = {
    let coordinator = MultiSendCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
    return coordinator
  }()

  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.loadCachedMarketAssets()
    self.startIntervalLoadingAssets()
    self.loadMarketAssets()
  }

  func stop() {
    self.loadTimer?.invalidate()
    self.loadTimer = nil
  }
  
  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }
  
  fileprivate func loadMarketAssets() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    provider.requestWithFilter(.getMarketingAssets) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(MarketingAssetsResponse.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateMarketingAssets(data.assets)
          Storage.store(data.assets, as: Constants.marketingAssetsStoreFileName)
        } catch let error {
          print("[Krytal] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Krytal] \(error.localizedDescription)")
      }
    }
  }
  
  fileprivate func loadCachedMarketAssets() {
    let assets = Storage.retrieve(Constants.marketingAssetsStoreFileName, as: [Asset].self) ?? []
    self.rootViewController.coordinatorDidUpdateMarketingAssets(assets)
  }
  
  fileprivate func startIntervalLoadingAssets() {
    self.loadTimer?.invalidate()
    self.loadTimer = nil
    self.loadTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.minutes5,
      repeats: true,
      block: { [weak self] timer in
        guard let `self` = self else { return }
        self.loadMarketAssets()
      }
    )
  }
  
  fileprivate func openSendTokenView(recipientAddress: String = "") {
    let from: TokenObject = KNGeneralProvider.shared.quoteTokenObject
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
  
  fileprivate func openKrytalView() {
    let coordinator = KrytalCoordinator(navigationController: self.navigationController)
    coordinator.start()
    self.krytalCoordinator = coordinator
  }
  
  fileprivate func openRewardView() {
    let coordinator = RewardCoordinator(navigationController: self.navigationController)
    coordinator.start()
    self.rewardCoordinator = coordinator
    
  }
  
  fileprivate func openBridgeView() {
    let coordinator = BridgeCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
    coordinator.start()
    self.bridgeCoordinator = coordinator
  }
  
  func openHistoryScreen() {
      AppDependencies.router.openTransactionHistory()
  }
  
  func openDappBrowserScreen() {
    self.dappCoordinator = nil
    let coordinator = DappCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
    coordinator.start()
    self.dappCoordinator = coordinator
  }
  
  func openBuyCryptoScreen() {
    self.buyCryptoCoordinator = nil
    let coordinator = BuyCryptoCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
    coordinator.start()
    self.buyCryptoCoordinator = coordinator
  }
  
    func openLoyalty() {
//        guard let url = URL(string: KNEnvironment.default.krystalWebUrl + "/loyalty" + "?preview=true") else { return }
//        DappBrowser.openURL(navigationController: navigationController, url: url)
        let coordinator = DappCoordinator(navigationController: navigationController)
        self.dappCoordinator = coordinator
        coordinator.openBrowserScreen(searchText: KNEnvironment.default.krystalWebUrl + "/loyalty?preview=true")
    }
    
  func openRewardHunting() {
    let coordinator = RewardHuntingCoordinator(navigationController: self.navigationController)
    coordinator.start()
    coordinator.delegate = self
    self.rewardHuntingCoordinator = coordinator
  }

  func appCoordinatorPendingTransactionsDidUpdate() {
    self.sendCoordinator?.coordinatorDidUpdatePendingTx()
    self.bridgeCoordinator?.coordinatorDidUpdatePendingTx()
    self.buyCryptoCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.multiSendCoordinator.coordinatorDidUpdatePendingTx()
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate()
  }
  
  func appCoordinatorSwitchAddress() {
    self.rootViewController.coordinatorDidSwitchAddress()
    self.sendCoordinator?.coordinatorAppSwitchAddress()
    self.krytalCoordinator?.coordinatorAppSwitchAddress()
    self.rewardCoordinator?.appCoordinatorSwitchAddress()
    self.dappCoordinator?.appCoordinatorSwitchAddress()
    self.buyCryptoCoordinator?.appCoordinatorSwitchAddress()
    self.multiSendCoordinator.appCoordinatorSwitchAddress()
    self.bridgeCoordinator?.appCoordinatorSwitchAddress()
  }
  
  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if self.sendCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.rewardCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.dappCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.multiSendCoordinator.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.historyCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.bridgeCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    return false
  }
  
  func appCoordinatorDidUpdateChain() {
    self.rootViewController.coordinatorDidUpdateChain()
    self.loadMarketAssets()
    self.dappCoordinator?.appCoordinatorDidUpdateChain()
    self.bridgeCoordinator?.appCoordinatorDidUpdateChain()
  }
}

extension InvestCoordinator: InvestViewControllerDelegate {
  func investViewController(_ controller: InvestViewController, run event: InvestViewEvent) {
    switch event {
    case .openLink(url: let url):
      controller.openSafari(with: url)
    case .swap:
      self.navigationController.tabBarController?.selectedIndex = 1
    case .transfer:
      self.openSendTokenView()
    case .reward:
      self.openRewardView()
      MixPanelManager.track("reward_open", properties: ["screenid": "reward"])
    case .krytal:
      self.openKrytalView()
    case .dapp:
      self.openDappBrowserScreen()
      MixPanelManager.track("dapp_open", properties: ["screenid": "dapp"])
    case .buyCrypto:
      self.openBuyCryptoScreen()
      MixPanelManager.track("buy_cryto_open", properties: ["screenid": "buy_cryto"])
    case .multiSend:
      self.multiSendCoordinator.start()
      Tracker.track(event: .exploreMultisend)
    case .promoCode:
      self.openPromotion(withCode: nil)
    case .rewardHunting:
      if currentAddress.isWatchWallet {
        self.rootViewController.showErrorTopBannerMessage(message: Strings.rewardHuntingWatchWalletErrorMessage)
      } else {
        self.openRewardHunting()
      }
    case .bridge:
      guard KNGeneralProvider.shared.currentChain.isSupportedBridge() else {
        self.navigationController.showErrorTopBannerMessage(message: Strings.unsupportedChain)
        return
      }
      self.openBridgeView()
    case .scanner:
      var acceptedResultTypes: [ScanResultType] = [.promotionCode]
      var scanModes: [ScanMode] = [.qr, .text]
      if KNGeneralProvider.shared.currentChain.isEVM {
        acceptedResultTypes.append(contentsOf: [.walletConnect, .ethPublicKey, .ethPrivateKey])
        scanModes = [.qr, .text]
      } else if KNGeneralProvider.shared.currentChain == .solana {
        acceptedResultTypes.append(contentsOf: [.solPublicKey, .solPrivateKey])
        scanModes = [.qr]
      }
      ScannerModule.start(previousScreen: ScreenName.explore, viewController: rootViewController, acceptedResultTypes: acceptedResultTypes, scanModes: scanModes) { [weak self] text, type in
        guard let self = self else { return }
        switch type {
        case .walletConnect:
          AppEventCenter.shared.didScanWalletConnect(address: self.currentAddress, url: text)
        case .ethPublicKey:
          self.openSendTokenView(recipientAddress: text)

        case .ethPrivateKey:
          let currentChain = KNGeneralProvider.shared.currentChain
          if currentChain.isEVM {
            self.openImportWalletFlow(privateKey: text, chain: currentChain)
          } else {
            self.openImportWalletFlow(privateKey: text, chain: .eth)
          }
        case .solPublicKey:
          self.openSendTokenView(recipientAddress: text)
        case .solPrivateKey:
          self.openImportWalletFlow(privateKey: text, chain: .solana)
        case .promotionCode:
          guard let code = ScannerUtils.getPromotionCode(text: text) else { return }
          self.openPromotion(withCode: code)
        case .seed:
            break
        }
      }
      MixPanelManager.track("scanner_open", properties: ["screenid": "scanner"])
    case .openApprovals:
        openApprovals()
    case .openLoyalty:
        openLoyalty()
    }
  }
  
  func openImportWalletFlow(privateKey: String, chain: ChainType) {
    let coordinator = KNImportWalletCoordinator(navigationController: navigationController)
    self.importWalletCoordinator = coordinator
    coordinator.delegate = self
    coordinator.startImportFlow(privateKey: privateKey, chain: chain)
  }
  
  func openPromotion(withCode code: String?) {
    let coordinator = PromoCodeCoordinator(navigationController: self.navigationController, code: code)
    coordinator.start()
    self.promoCodeCoordinator = coordinator
    MixPanelManager.track("promotion_open", properties: ["screenid": "promotion"])
  }
    
    func openApprovals() {
        let coordinator = ApprovalsCoordinator(navigationController: navigationController)
        coordinator.onCompleted = { [weak self] in
            self?.removeCoordinator(coordinator)
        }
        coordinate(coordinator: coordinator)
    }
  
}

extension InvestCoordinator: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.investCoordinatorDidSelectAddToken(token)
  }
  
}

extension InvestCoordinator: KNHistoryCoordinatorDelegate {
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.investCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }
}

extension InvestCoordinator: BuyCryptoCoordinatorDelegate {
  func buyCryptoCoordinatorDidClose() {
    self.buyCryptoCoordinator = nil
  }
  
  func buyCryptoCoordinatorDidSelectAddWallet() {
     self.delegate?.investCoordinatorDidSelectAddWallet()
  }
  
  func buyCryptoCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
  }
  
  func buyCryptoCoordinatorOpenHistory() {
    self.openHistoryScreen()
  }
}

extension InvestCoordinator: DappCoordinatorDelegate {
  func dAppCoordinatorDidSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }
  
  func dAppCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
  }
  
  func dAppCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.investCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
}

extension InvestCoordinator: BridgeCoordinatorDelegate {
  func didSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.investCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
  
  func didSelectOpenHistoryList() {
    self.openHistoryScreen()
  }
}

extension InvestCoordinator: RewardHuntingCoordinatorDelegate {
  
  func openRewards() {
    self.openRewardView()
  }
  
}

extension InvestCoordinator: KNImportWalletCoordinatorDelegate {
  
  func importWalletCoordinatorDidImport(wallet: KWallet, chain: ChainType) {
    delegate?.investCoordinator(didAdd: wallet, chain: chain)
    navigationController.popViewController(animated: true, completion: nil)
  }
  
  func importWalletCoordinatorDidImport(watchAddress: KAddress, chain: ChainType) {
    delegate?.investCoordinator(didAdd: watchAddress, chain: chain)
  }
  
  func importWalletCoordinatorDidClose() {
    importWalletCoordinator = nil
  }

}
