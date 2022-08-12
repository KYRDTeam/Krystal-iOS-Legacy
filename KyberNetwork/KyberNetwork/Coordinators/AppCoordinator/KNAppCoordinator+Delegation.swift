// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KrystalWallets

// MARK: Landing Page Coordinator Delegate
extension KNAppCoordinator: KNLandingPageCoordinatorDelegate {
  
  func landingPageCoordinatorDidSendRefCode(_ code: String) {
    self.sendRefCode(code.uppercased())
  }
  
  func landingPageCoordinator(import wallet: KWallet, chain: ChainType) {
    switchWallet(wallet: wallet, chain: chain)
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
    self.overviewTabCoordinator?.navigationController.popToRootViewController(animated: true, completion: {
      self.overviewTabCoordinator?.openChartView(token: token, chainId: nil)
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
  
  func earnCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func earnCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func earnCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.addNewWallet(type: .chain(chainType: chainType))
  }
}

extension KNAppCoordinator: OverviewCoordinatorDelegate {
  func overviewCoordinatorDidSelectAllChain() {
    self.loadBalanceCoordinator?.shouldFetchAllChain = true
    self.loadBalanceCoordinator?.resume()
  }
  func overviewCoordinatorDidImportWallet(wallet: KWallet, chainType: ChainType) {
    switchWallet(wallet: wallet, chain: chainType)
  }
  
  func overviewCoordinatorDidStart() {
    if self.isFirstLoad {
      self.showBackupWalletIfNeeded()
      self.isFirstLoad = false
    }
  }

  func overviewCoordinatorDidSelectExportWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectExportWallet()
  }

  func overviewCoordinatorDidSelectDeleteWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectDeleteWallet()
  }

  func overviewCoordinatorDidSelectRenameWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectRenameWallet()
  }

  func overviewCoordinatorDidChangeHideBalanceStatus(_ status: Bool) {
    self.earnCoordinator?.appCoodinatorDidUpdateHideBalanceStatus(status)
  }

  func overviewCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }

  func overviewCoordinatorDidSelectDepositMore(tokenAddress: String) {
    self.tabbarController.selectedIndex = 3
    self.earnCoordinator?.appCoodinatorDidOpenEarnView(tokenAddress: tokenAddress)
  }

  func overviewCoordinatorDidSelectSwapToken(token: Token, isBuy: Bool) {
    //TODO: temp use token realm object for swap atm, support custom token
    let tokenObject = KNSupportedTokenStorage.shared.get(forPrimaryKey: token.address.lowercased()) ?? KNGeneralProvider.shared.quoteTokenObject
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(tokenObject, isReceived: isBuy)
    self.tabbarController.selectedIndex = 1
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
  
  func settingsCoordinatorDidImportDeepLinkTokens(srcToken: TokenObject?, destToken: TokenObject?) {
    self.exchangeCoordinator?.appCoordinatorReceivedTokensSwapFromUniversalLink(srcTokenAddress: srcToken?.address, destTokenAddress: destToken?.address, chainIdString: "\(KNGeneralProvider.shared.customRPC.chainID)")
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

// MARK: Add wallet coordinator delegate
extension KNAppCoordinator: KNAddNewWalletCoordinatorDelegate {
  
  func addNewWalletCoordinator(didAdd wallet: KWallet, chain: ChainType) {
    switchWallet(wallet: wallet, chain: chain)
  }
  
  func addNewWalletCoordinator(didAdd watchAddress: KAddress, chain: ChainType) {
    switchToWatchAddress(address: watchAddress, chain: chain)
  }
  
  func addNewWalletCoordinatorDidSendRefCode(_ code: String) {
    self.sendRefCode(code.uppercased())
  }

  func addNewWalletCoordinator(remove wallet: KWallet) {

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
  func passcodeCoordinatorDidCancel() {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidEvaluatePIN() {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidCreatePasscode() {
    self.authenticationCoordinator.stop {}
  }
}

//extension KNAppCoordinator: KNExploreCoordinatorDelegate {
//  func exploreCoordinatorOpenManageOrder() {
////    self.tabbarController.selectedIndex = 2
////    self.limitOrderCoordinator?.appCoordinatorOpenManageOrder()
//  }
//
//  func exploreCoordinatorOpenSwap(from: String, to: String) {
//    self.tabbarController.selectedIndex = 1
//    self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
//  }
//}

extension KNAppCoordinator: SwapV2CoordinatorDelegate {
  
  func swapV2CoordinatorDidSelectManageWallets() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func swapV2CoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func swapV2CoordinatorDidSelectAddWalletForChain(chain: ChainType) {
    self.addNewWallet(type: .chain(chainType: chain))
  }

}
