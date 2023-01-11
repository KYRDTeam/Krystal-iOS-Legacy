// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import OneSignal
import KrystalWallets
import Dependencies
import AppState
import TransactionModule
import SwapModule
import EarnModule

// MARK: This file for handling in session
extension KNAppCoordinator {
  
  func startNewSession(address: KAddress) {
      GasPriceManager.shared.scheduleFetchAllChainGasPrice()
    
    AppState.shared.updateAddress(address: address, targetChain: AppState.shared.currentChain)
      
    OneSignal.setExternalUserId(address.addressString)
    Tracker.updateUserID(address.addressString)
    self.session = KNSession()
    self.session.startSession()
    
    DispatchQueue.global(qos: .background).async {
      _ = KNSupportedTokenStorage.shared
      _ = BalanceStorage.shared
      _ = KNTrackerRateStorage.shared
    }
    
    FeatureFlagManager.shared.configClient(session: self.session)
    self.tabbarController = KNTabBarController()
    self.tabbarController.delegate = self
    
    let overviewCoordinator = OverviewCoordinator()
    self.addCoordinator(overviewCoordinator)
    overviewCoordinator.delegate = self
    overviewCoordinator.start()
    self.overviewTabCoordinator = overviewCoordinator
    
    self.loadBalanceCoordinator?.exit()
    self.loadBalanceCoordinator = nil
    self.loadBalanceCoordinator = KNLoadBalanceCoordinator()
    self.loadBalanceCoordinator?.delegate = self
    AppState.shared.isSelectedAllChain = self.overviewTabCoordinator?.rootViewController.viewModel.currentChain == .all
    self.loadBalanceCoordinator?.resume()

    // Settings tab
    self.settingsCoordinator = {
      let coordinator = KNSettingsCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    
    let investCoordinator = InvestCoordinator()
    investCoordinator.delegate = self
    investCoordinator.start()
    self.investCoordinator = investCoordinator

    self.addCoordinator(self.settingsCoordinator!)
    self.settingsCoordinator?.start()
    
      let isSwapModuleEnabled = AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.swapModule)
      let isEarnV2Enabled = AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.earnV2)
      
      if isSwapModuleEnabled {
          self.swapModuleCoordinator = SwapModule.createSwapCoordinator()
          self.swapModuleCoordinator?.start()
          self.swapModuleCoordinator?.navigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tabbar_swap_icon"),
            selectedImage: nil
          )
          self.swapModuleCoordinator?.navigationController.tabBarItem.tag = 1
      } else {
          self.swapV2Coordinator = SwapV2Coordinator()
          self.swapV2Coordinator?.start()
          self.swapV2Coordinator?.navigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tabbar_swap_icon"),
            selectedImage: nil
          )
          self.swapV2Coordinator?.navigationController.tabBarItem.tag = 1
      }
      
      if isEarnV2Enabled {
          self.earnModuleCoordinator = EarnModuleCoordinator()
          self.earnModuleCoordinator?.start()
          self.earnModuleCoordinator?.navigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tabbar_earn_icon"),
            selectedImage: nil
          )
          self.earnModuleCoordinator?.navigationController.tabBarItem.tag = 3
          self.earnModuleCoordinator?.navigationController.tabBarItem.accessibilityIdentifier = "menuEarn"
      } else {
          self.earnCoordinator = {
              let coordinator = EarnCoordinator()
              coordinator.delegate = self
              return coordinator
          }()
          self.earnCoordinator?.start()
          self.earnCoordinator?.navigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tabbar_earn_icon"),
            selectedImage: nil
          )
          self.earnCoordinator?.navigationController.tabBarItem.tag = 3
          self.earnCoordinator?.navigationController.tabBarItem.accessibilityIdentifier = "menuEarn"
      }
      
  self.tabbarController.viewControllers = [
    self.overviewTabCoordinator!.navigationController,
    isSwapModuleEnabled ? self.swapModuleCoordinator!.navigationController : self.swapV2Coordinator!.navigationController,
    self.investCoordinator!.navigationController,
    isEarnV2Enabled ? self.earnModuleCoordinator!.navigationController : self.earnCoordinator!.navigationController,
    self.settingsCoordinator!.navigationController,
  ]
    
    self.tabbarController.tabBar.tintColor = UIColor(named: "buttonBackgroundColor")
    if #available(iOS 15.0, *) {
      let apperance = UITabBarAppearance()
      apperance.configureWithOpaqueBackground()
      apperance.backgroundColor = UIColor(named: "toolbarBgColor")
      
      self.tabbarController.tabBar.standardAppearance = apperance
      self.tabbarController.tabBar.scrollEdgeAppearance = self.tabbarController.tabBar.standardAppearance
    } else {
      self.tabbarController.tabBar.barTintColor = UIColor(named: "toolbarBgColor")
    }
    
    self.overviewTabCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_summary_icon"),
      selectedImage: nil
    )
    self.overviewTabCoordinator?.navigationController.tabBarItem.tag = 0
    self.overviewTabCoordinator?.navigationController.tabBarItem.accessibilityIdentifier = "menuHome"

    self.investCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_invest_icon"),
      selectedImage: nil
    )
    self.investCoordinator?.navigationController.tabBarItem.tag = 2
    self.investCoordinator?.navigationController.tabBarItem.accessibilityIdentifier = "menuExplore"

    if AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.earnNewTag) {
        self.tabbarController.addNewTag(toItemAt: 3)
    }

    self.settingsCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_setting_icon"),
      selectedImage: nil
    )
    self.settingsCoordinator?.navigationController.tabBarItem.tag = 4
    self.settingsCoordinator?.navigationController.tabBarItem.accessibilityIdentifier = "menuSetting"

    self.tabbarController.setupTabbarConstraints()
      
    self.navigationController.pushViewController(self.tabbarController, animated: true) {
    }

    self.addObserveNotificationFromSession()
    self.updateLocalData()

    KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      
    self.doLogin { _ in }
    UserService().connectEVM(address: address) {}
  }
  
  func stopAllSessions() {
    self.walletManager.removeAll()
    self.session.stopSession()
    AppState.shared.updateAddress(address: self.walletManager.createEmptyAddress(), targetChain: AppState.shared.currentChain)
    self.settingsCoordinator?.stop()
    self.overviewTabCoordinator?.stop()
    self.overviewTabCoordinator?.start()
//    self.tabbarController.selectedIndex = 0
  }

  func restartSession(address: KAddress) {
    EtherscanTransactionStorage.shared.updateCurrentHistoryCache()
    self.session.switchAddress(address: address)
    FeatureFlagManager.shared.configClient(session: self.session)
    AppState.shared.isSelectedAllChain = self.overviewTabCoordinator?.rootViewController.viewModel.currentChain == .all
    self.loadBalanceCoordinator?.restartNewSession(self.session)
    self.investCoordinator?.appCoordinatorSwitchAddress()
    
    KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
    self.overviewTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    
    self.doLogin { _ in }
    UserService().connectEVM(address: address) {}
    
    NotificationCenter.default.post(
      name: Notification.Name(kAppDidUpdateNewSession),
      object: nil,
      userInfo: ["session": self.session]
    )

    MixPanelManager.shared.updateWalletAddress(address: address.addressString)
    Tracker.updateUserID(address.addressString)
    MixPanelManager.shared.setDistintID(address)
  }
  
  private func switchToLastImportedAddress() {
    if let address = walletManager.getAllAddresses().last {
      guard let chain = ChainType.allCases.first(where: { chainType in
        chainType.addressType == address.addressType
      }) else {
        try? self.walletManager.removeAddress(address: address)
        self.switchToLastImportedAddress()
        return
      }
      if address.isWatchWallet {
        self.switchToWatchAddress(address: address, chain: chain)
      } else if let wallet = walletManager.wallet(forAddress: address) {
        self.switchWallet(wallet: wallet, chain: chain)
      } else {
        try? self.walletManager.removeAddress(address: address)
        self.switchToLastImportedAddress()
        return
      }
    } else {
      stopAllSessions()
    }
  }
  
  func onAddWallet(wallet: KWallet, chain: ChainType) {
    self.switchWallet(wallet: wallet, chain: chain)
    AppDelegate.shared.coordinator.overviewTabCoordinator?.stop()
    AppDelegate.shared.coordinator.overviewTabCoordinator?.rootViewController.viewModel.currentChain = chain
    AppDelegate.shared.coordinator.overviewTabCoordinator?.start()
  }
  
  func onAddWatchAddress(address: KAddress, chain: ChainType) {
    switchToWatchAddress(address: address, chain: chain)
  }
  
  func onRemoveWallet(wallet: KWallet) {
    if wallet.id == session.address.walletID {
        NonceCache.shared.resetNonce(wallet: wallet)
        AppState.shared.unmarkWalletBackedUp(walletID: wallet.id)
        session.clearWalletData(wallet: wallet)
        switchToNextAddress(of: session.address)
    }
  }
  
  func switchToNextAddress(of address: KAddress) {
    if let nextAddress = walletManager.getAllAddresses(addressType: address.addressType).last {
      if nextAddress.isWatchWallet {
        self.switchToWatchAddress(address: nextAddress, chain: KNGeneralProvider.shared.currentChain)
      } else if let wallet = walletManager.wallet(forAddress: nextAddress) {
          switchWallet(wallet: wallet, chain: KNGeneralProvider.shared.currentChain)
          AppState.shared.updateAddress(address: AppState.shared.currentAddress, targetChain: AppState.shared.currentChain)
      } else {
        switchToLastImportedAddress()
      }
    } else {
      switchToLastImportedAddress()
    }
  }
  
  func onRemoveWatchAddress(address: KAddress) {
    switchToNextAddress(of: address)
  }

  func addNewWallet(type: AddNewWalletType) {
    self.navigationController.present(
      self.addWalletCoordinator.navigationController,
      animated: false
    ) {
      self.addWalletCoordinator.start(type: type)
    }
  }

  func addPromoCode() {
    self.promoCodeCoordinator = nil
    self.promoCodeCoordinator = KNPromoCodeCoordinator(
      navigationController: self.navigationController
    )
    self.promoCodeCoordinator?.delegate = self
    self.promoCodeCoordinator?.start()
  }

  fileprivate func updateLocalData() {
    self.tokenBalancesDidUpdateNotification(nil)
    self.exchangeRateTokenDidUpdateNotification(nil)
    self.tokenObjectListDidUpdate(nil)
//    self.tokenTransactionListDidUpdate(nil)
  }
}
