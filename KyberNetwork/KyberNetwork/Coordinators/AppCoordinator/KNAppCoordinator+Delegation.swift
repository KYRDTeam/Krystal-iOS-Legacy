// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KrystalWallets
import AppState
import Dependencies

// MARK: Landing Page Coordinator Delegate
extension KNAppCoordinator: KNLandingPageCoordinatorDelegate {
  
  func landingPageCoordinatorDidSendRefCode(_ code: String) {
    self.sendRefCode(code.uppercased())
  }
  
  func landingPageCoordinator(import wallet: KWallet, chain: ChainType) {
    switchWallet(wallet: wallet, chain: chain)
  }
  
  func landingPageCoordinatorStartedBrowsing() {
    let address = walletManager.createEmptyAddress()
    self.startNewSession(address: address)
  }
  
  func landingPageCoordinator(add watchAddress: KAddress, chain: ChainType) {
    
  }
}

// MARK: Session Delegate
extension KNAppCoordinator: KNSessionDelegate {
  func userDidClickExitSession() {
    let alertController = KNPrettyAlertController(
      title: "exit".toBeLocalised(),
      message: "do.you.want.to.exit.and.remove.all.wallets".toBeLocalised(),
      secondButtonTitle: "OK".toBeLocalised(),
      firstButtonTitle: "cancel".toBeLocalised(),
      secondButtonAction: {
        self.stopAllSessions()
      },
      firstButtonAction: nil
    )
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: Exchange Token Coordinator Delegate
extension KNAppCoordinator: KNExchangeTokenCoordinatorDelegate {
  func exchangeTokenCoordinatorDidSelectTokens(token: Token) {
    self.tabbarController.selectedIndex = 0
    self.overviewTabCoordinator?.navigationController.popToRootViewController(animated: false, completion: {
      self.overviewTabCoordinator?.openChartView(token: token, chainId: nil, animated: false)
    })
  }
  
  func exchangeTokenCoordinatorRemoveWallet(_ wallet: KWallet) {
    onRemoveWallet(wallet: wallet)
  }
  
  func exchangeTokenCoordinator(didAdd wallet: KWallet, chain: ChainType) {
    switchWallet(wallet: wallet, chain: chain)
  }
  
  func exchangeTokenCoordinator(didAdd watchAddress: KAddress, chain: ChainType) {
    switchToWatchAddress(address: watchAddress, chain: chain)
  }
  
  func exchangeTokenCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.addNewWallet(type: .chain(chainType: chainType))
  }
  
  func exchangeTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }
  
  func exchangeTokenCoordinatorDidAddTokens(srcToken: TokenObject?, destToken: TokenObject?) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidAddTokens(srcToken: srcToken, destToken: destToken)
  }
  
  func exchangeTokenCoodinatorDidSendRefCode(_ code: String) {
    self.sendRefCode(code.uppercased())
  }
  
  func exchangeTokenCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func exchangeTokenCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }

  func exchangeTokenCoordinatorDidSelectPromoCode() {
    self.addPromoCode()
  }

  func exchangeTokenCoordinatorOpenManageOrder() {
//    self.tabbarController.selectedIndex = 2
//    self.limitOrderCoordinator?.appCoordinatorOpenManageOrder()
  }
}

extension KNAppCoordinator: EarnCoordinatorDelegate {
  func earnCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }
}

extension KNAppCoordinator: OverviewCoordinatorDelegate {
  
  func overviewCoordinatorOpenPromotion(code: String) {
    self.tabbarController.selectedIndex = 2
    self.investCoordinator?.openPromotion(withCode: code)
  }
  
  func overviewCoordinatorDidSelectAllChain() {
    AppState.shared.isSelectedAllChain = true
    self.loadBalanceCoordinator?.resume()
  }
  
  func overviewCoordinatorDidImportWallet(wallet: KWallet, chainType: ChainType) {
    switchWallet(wallet: wallet, chain: chainType)
  }
  
  func overviewCoordinatorDidStart() {
  }
    
    func overviewCoordinatorDidChangeHideBalanceStatus(_ status: Bool) {
      self.earnCoordinator?.appCoodinatorDidUpdateHideBalanceStatus(status)
    }

  func overviewCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }

  func overviewCoordinatorDidSelectDepositMore(tokenAddress: String) {
      if AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.earnV2) {
          AppDependencies.router.openEarn()
      } else {
          self.earnCoordinator?.navigationController.popToRootViewController(animated: false)
          self.tabbarController.selectedIndex = 3
          self.earnCoordinator?.appCoodinatorDidOpenEarnView(tokenAddress: tokenAddress)
      }
  }

  func overviewCoordinatorDidSelectSwapToken(token: Token, isBuy: Bool) {
      self.tabbarController.selectedIndex = 1
      if AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.swapModule) {
          self.swapModuleCoordinator?.appCoordinatorShouldOpenExchangeForToken(token, isReceived: isBuy)
      } else {
          self.swapV2Coordinator?.appCoordinatorShouldOpenExchangeForToken(token, isReceived: isBuy)
      }
  }
  
  func overviewCoordinatorOpenCreateChainWalletMenu(chainType: ChainType) {
    self.addNewWallet(type: .chain(chainType: chainType))
  }
  
  func overviewCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }

  func overviewCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func overviewCoordinatorDidPullToRefresh(mode: ViewMode, overviewMode: OverviewMode) {
    self.loadBalanceCoordinator?.appCoordinatorRefreshData(mode: mode, overviewMode:overviewMode)
  }
  
  func overviewCoordinatorBuyCrypto() {
    self.tabbarController.selectedIndex = 2
    self.investCoordinator?.openBuyCryptoScreen()
  }
}

extension KNAppCoordinator: KrytalCoordinatorDelegate {
  func krytalCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func krytalCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
}

extension KNAppCoordinator: InvestCoordinatorDelegate {
  
  func investCoordinator(didAdd wallet: KWallet, chain: ChainType) {
    switchWallet(wallet: wallet, chain: chain)
  }
  
  func investCoordinator(didAdd watchAddress: KAddress, chain: ChainType) {
    switchToWatchAddress(address: watchAddress, chain: chain)
  }
  
  func investCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.addNewWallet(type: .chain(chainType: chainType))
  }
  
  func investCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }
  
  func investCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func investCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
}

extension KNAppCoordinator: KNLoadBalanceCoordinatorDelegate {
  func loadBalanceCoordinatorDidGetLP(chainLP: [ChainLiquidityPoolModel]) {
    self.overviewTabCoordinator?.rootViewController.coordinatorDidUpdateAllLPData(models: chainLP)
  }
  
  func loadBalanceCoordinatorDidGetBalance(chainBalances: [ChainBalanceModel]) {
    self.overviewTabCoordinator?.rootViewController.coordinatorDidUpdateAllTokenData(models: chainBalances)
  }
}

// MARK: Settings Coordinator Delegate
extension KNAppCoordinator: KNSettingsCoordinatorDelegate {
  
  func settingsCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.addNewWallet(type: .chain(chainType: chainType))
  }
  
  func settingsCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func settingsCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func settingsCoordinatorUserDidSelectExit() {
    self.userDidClickExitSession()
  }
  
  func settingsCoordinatorUserDidRemoveWallet(_ wallet: KWallet) {
    onRemoveWallet(wallet: wallet)
  }
  
  func settingsCoordinatorUserDidRemoveWatchAddress(_ address: KAddress) {
    onRemoveWatchAddress(address: address)
  }
  
  func settingsCoordinatorUserDidSelectRemoveCurrentWallet() {
    let currentAddress = session.address
    if currentAddress.isWatchWallet {
      try? walletManager.removeAddress(address: currentAddress)
      onRemoveWatchAddress(address: currentAddress)
    } else if let wallet = walletManager.wallet(forAddress: currentAddress) {
      try? walletManager.remove(wallet: wallet)
      onRemoveWallet(wallet: wallet)
    } else {
      switchToNextAddress(of: currentAddress)
    }
  }

  func settingsCoordinatorUserDidSelectAddWallet(type: AddNewWalletType) {
    self.addNewWallet(type: type)
  }
}

// MARK: Transaction Status Delegate
extension KNAppCoordinator: KNTransactionStatusCoordinatorDelegate {
  func transactionStatusCoordinatorDidClose() {
    self.transactionStatusCoordinator = nil
    let trans = self.session.transactionStorage.kyberTransactions.filter({ return $0.state != .pending })
    if !trans.isEmpty { self.session.transactionStorage.delete(trans) }
  }
}

extension KNAppCoordinator: KNPromoCodeCoordinatorDelegate {
  func promoCodeCoordinatorDidCreate(_ address: KAddress, expiredDate: TimeInterval, destinationToken: String?, destAddress: String?, name: String?) {
    self.navigationController.popViewController(animated: true) {
      KNWalletPromoInfoStorage.shared.addWalletPromoInfo(
        address: address.addressString,
        destinationToken: destinationToken ?? "",
        destAddress: destAddress,
        expiredTime: expiredDate
      )
      self.session.switchAddress(address: address)
    }
  }
}

// MARK: Passcode coordinator delegate
extension KNAppCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
    self.authenticationCoordinator.stop {}
  }
}

extension KNAppCoordinator: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    switch tabBarController.selectedIndex {
    case 0:
      MixPanelManager.track("homepage", properties: ["screenid": "global"])
    case 1:
      MixPanelManager.track("swap", properties: ["screenid": "global"])
    case 2:
      MixPanelManager.track("explore", properties: ["screenid": "global"])
    case 3:
      MixPanelManager.track("earn", properties: ["screenid": "global"])
    case 4:
      MixPanelManager.track("settings", properties: ["screenid": "global"])
    default:
      break
    }
  }
}
