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
  
  var stakingViewController: StakingViewController?
  
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
  
  fileprivate func openStakeView() {
//    let viewModel = EarnOverViewModel()
//    let viewController = EarnOverviewV2Controller(viewModel: viewModel)
//    viewController.delegate = self
    
    let viewController = AppDependencies.router.createEarnOverViewController()
    self.navigationController.pushViewController(viewController, animated: true)
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
  
  private func openSetupStakeView(platform: EarnPlatform, pool: EarnPoolModel) {
    let vc = StakingViewController.instantiateFromNib()
    vc.viewModel = StakingViewModel(pool: pool, platform: platform)
    vc.delegate = self
    navigationController.pushViewController(vc, animated: true)
    stakingViewController = vc
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
        }
      }
      MixPanelManager.track("scanner_open", properties: ["screenid": "scanner"])
    case .stake:
      self.openStakeView()
    case .openApprovals:
        openApprovals()
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
  
  func openStakeSummary(txObject: TxObject, settings: UserSettings, displayInfo: StakeDisplayInfo) {
    let vm = StakingSummaryViewModel(txObject: txObject, settings: settings, displayInfo: displayInfo)
    let vc = StakingSummaryViewController(viewModel: vm)
    let sheet = SheetViewController(controller: vc, sizes: [.fixed(560)], options: .init(pullBarHeight: 0))
    vc.delegate = self
    navigationController.present(sheet, animated: true)
  }
  
  func openStakeProcess(_ tx: InternalHistoryTransaction) {
    let vc = StakingTrasactionProcessPopup(transaction: tx)
    vc.delegate = self
    navigationController.present(vc, animated: true)
  }
  
}

extension InvestCoordinator: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidClose() {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.investCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
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

extension InvestCoordinator: EarnOverviewV2ControllerDelegate {
  func didSelectPlatform(platform: EarnPlatform, pool: EarnPoolModel) {
    openSetupStakeView(platform: platform, pool: pool)
  }
}

extension InvestCoordinator: StakingViewControllerDelegate {
  func sendApprove(_ viewController: StakingViewController, tokenAddress: String, remain: BigInt, symbol: String, toAddress: String) {
    let vm = ApproveTokenViewModelForTokenAddress(address: tokenAddress, remain: remain, state: false, symbol: symbol)
    vm.toAddress = toAddress
    let vc = ApproveTokenViewController(viewModel: vm)

    vc.delegate = self
    navigationController.present(vc, animated: true, completion: nil)
    
  }
  
  func didSelectNext(_ viewController: StakingViewController, settings: UserSettings, txObject: TxObject, displayInfo: StakeDisplayInfo) {
    openStakeSummary(txObject: txObject, settings: settings, displayInfo: displayInfo)
  }
  
}

extension InvestCoordinator: StakingSummaryViewControllerDelegate {
  func didSendTransaction(viewController: StakingSummaryViewController, internalTransaction: InternalHistoryTransaction) {
    viewController.dismiss(animated: true) {
      self.openStakeProcess(internalTransaction)
    }
    
  }
}

extension InvestCoordinator: StakingProcessPopupDelegate {
  func stakingProcessPopup(_ controller: StakingTrasactionProcessPopup, action: StakingProcessPopupEvent) {
    switch action {
    case .openLink(let url):
      navigationController.openSafari(with: url)
    case .goToSupport:
      navigationController.openSafari(with: Constants.supportURL)
    case .viewToken(let sym):
      if let token = KNSupportedTokenStorage.shared.getTokenWith(symbol: sym) {
        controller.dismiss(animated: false) {
          AppDelegate.shared.coordinator.exchangeTokenCoordinatorDidSelectTokens(token: token)
        }
      }
    case .close:
      controller.dismiss(animated: true)
    }
  }
}

extension InvestCoordinator: ApproveTokenViewControllerDelegate {
  func approveTokenViewControllerDidSelectGasSetting(_ controller: ApproveTokenViewController, gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) {
    
  }
  
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: String, value: BigInt) {
    
  }

  fileprivate func sendApprove(_ tokenAddress: String, _ toAddress: String?, _ address: String, _ gasLimit: BigInt) {
    let processor = EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
    processor.sendApproveERCTokenAddress(owner: self.currentAddress, tokenAddress: tokenAddress, value: Constants.maxValueBigInt, gasPrice: KNGasCoordinator.shared.defaultKNGas, toAddress: toAddress) { approveResult in
      switch approveResult {
      case .success:
        self.stakingViewController?.coordinatorSuccessApprove(address: address)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.localizedDescription,
          time: 1.5
        )
        self.stakingViewController?.coordinatorFailApprove(address: address)
      }
    }
  }
  
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt) {
    if currentAddress.isWatchWallet {
      return
    }
    guard remain.isZero else {
      self.resetAllowanceBeforeSend(address, toAddress, address, gasLimit)
      return
    }
    self.sendApprove(address, toAddress, address, gasLimit)
  }

  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt, gasLimit: BigInt) {
  }

  fileprivate func resetAllowanceBeforeSend(_ tokenAddress: String, _ toAddress: String?, _ address: String, _ gasLimit: BigInt) {
    let processor = EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
    processor.sendApproveERCTokenAddress(owner: self.currentAddress, tokenAddress: tokenAddress, value: BigInt(0), gasPrice: KNGasCoordinator.shared.defaultKNGas, toAddress: toAddress) { approveResult in
      switch approveResult {
      case .success:
        self.sendApprove(tokenAddress, toAddress, address, gasLimit)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.localizedDescription,
          time: 1.5
        )
      }
    }
  }
}
