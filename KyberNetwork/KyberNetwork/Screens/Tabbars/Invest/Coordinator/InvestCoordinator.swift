//
//  InvestCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/12/21.
//

import Foundation
import Moya
import BigInt
import KrystalWallets

protocol InvestCoordinatorDelegate: class {
  func investCoordinatorDidSelectManageWallet()
  func investCoordinatorDidSelectAddWallet()
  func investCoordinatorDidSelectAddToken(_ token: TokenObject)
  func investCoordinatorDidSelectAddChainWallet(chainType: ChainType)
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
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getMarketingAssets) { (result) in
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
  
  fileprivate func openSendTokenView() {
    let from: TokenObject = KNGeneralProvider.shared.quoteTokenObject
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      balances: self.balances,
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }
  
  fileprivate func openKrytalView() {
    let coordinator = KrytalCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
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
    self.sendCoordinator?.appCoordinatorDidUpdateChain()
    self.dappCoordinator?.appCoordinatorDidUpdateChain()
    self.multiSendCoordinator.appCoordinatorDidUpdateChain()
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
    case .krytal:
      self.openKrytalView()
    case .dapp:
      self.openDappBrowserScreen()
    case .buyCrypto:
      self.openBuyCryptoScreen()
    case .multiSend:
      self.multiSendCoordinator.start()
      KNCrashlyticsUtil.logCustomEvent(withName: "explore_multiple_transfer", customAttributes: nil)
    case .promoCode:
      let coordinator = PromoCodeCoordinator(navigationController: self.navigationController)
      coordinator.start()
      self.promoCodeCoordinator = coordinator
    case .rewardHunting:
      if currentAddress.isWatchWallet {
        self.rootViewController.showErrorTopBannerMessage(message: Strings.rewardHuntingWatchWalletErrorMessage)
      } else {
        self.openRewardHunting()
      }
    case .bridge:
      self.openBridgeView()
    case .addChainWallet(let chainType):
      delegate?.investCoordinatorDidSelectAddChainWallet(chainType: chainType)

    }
  }
}

extension InvestCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.investCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
  
  func sendTokenCoordinatorDidClose() {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.investCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
  }
  
  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }
}

extension InvestCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.investCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.investCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }
  
  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }
}

extension InvestCoordinator: KrytalCoordinatorDelegate {
  func krytalCoordinatorDidSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }
  
  func krytalCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
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
  
  func didSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }

  func didSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
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
