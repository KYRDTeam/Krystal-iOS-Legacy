// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import OneSignal
import KrystalWallets

// MARK: This file for handling in session
extension KNAppCoordinator {
  
  func startNewSession(address: KAddress) {
    self.walletCache.lastUsedAddress = address
    self.currentAddress = address
    OneSignal.setExternalUserId(address.addressString)
    Tracker.updateUserID(address.addressString)
    self.session = KNSession(address: address)
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
    self.loadBalanceCoordinator?.shouldFetchAllChain = self.overviewTabCoordinator?.rootViewController.viewModel.currentChain == .all
    self.loadBalanceCoordinator?.resume()

    // KyberSwap Tab
    self.exchangeCoordinator = {
      let coordinator = KNExchangeTokenCoordinator()
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.exchangeCoordinator!)
    self.exchangeCoordinator?.start()

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

    self.earnCoordinator = {
      let coordinator = EarnCoordinator()
      coordinator.delegate = self
      return coordinator
    }()
    self.earnCoordinator?.start()

    self.addCoordinator(self.settingsCoordinator!)
    self.settingsCoordinator?.start()
    
    if FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.swapV2) {
      let swapV2Coordinator = SwapV2Coordinator()
      swapV2Coordinator.delegate = self
      swapV2Coordinator.start()
      swapV2Coordinator.navigationController.tabBarItem = UITabBarItem(
        title: nil,
        image: UIImage(named: "tabbar_swap_icon"),
        selectedImage: nil
      )
      swapV2Coordinator.navigationController.tabBarItem.tag = 1

      self.tabbarController.viewControllers = [
        self.overviewTabCoordinator!.navigationController,
        swapV2Coordinator.navigationController,
        self.investCoordinator!.navigationController,
        self.earnCoordinator!.navigationController,
        self.settingsCoordinator!.navigationController,
      ]
    } else {
      self.tabbarController.viewControllers = [
        self.overviewTabCoordinator!.navigationController,
        self.exchangeCoordinator!.navigationController,
        self.investCoordinator!.navigationController,
        self.earnCoordinator!.navigationController,
        self.settingsCoordinator!.navigationController,
      ]
    }
    
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

    self.exchangeCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_swap_icon"),
      selectedImage: nil
    )
    self.exchangeCoordinator?.navigationController.tabBarItem.tag = 1

    self.investCoordinator?.navigationController.tabBarItem.tag = 2
    self.investCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_invest_icon"),
      selectedImage: nil
    )

    self.earnCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_earn_icon"),
      selectedImage: nil
    )
    self.earnCoordinator?.navigationController.tabBarItem.tag = 3

    self.settingsCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_setting_icon"),
      selectedImage: nil
    )
    self.settingsCoordinator?.navigationController.tabBarItem.tag = 4

    self.navigationController.pushViewController(self.tabbarController, animated: true) {
    }

    self.addObserveNotificationFromSession()
    self.updateLocalData()

    KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)

    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()

    self.doLogin { _ in }
  }
  
  func stopAllSessions() {
    self.walletManager.removeAll()
    self.session.stopSession()
    self.session.address = self.walletManager.emptyAddress()
    self.exchangeCoordinator?.stop()
    self.exchangeCoordinator = nil
    self.settingsCoordinator?.stop()
    self.settingsCoordinator = nil
    self.overviewTabCoordinator?.stop()
    self.overviewTabCoordinator?.start()
    self.tabbarController.selectedIndex = 0
  }

  func restartSession(address: KAddress) {
    self.session.switchAddress(address: address)
    FeatureFlagManager.shared.configClient(session: self.session)
    self.loadBalanceCoordinator?.shouldFetchAllChain = self.overviewTabCoordinator?.rootViewController.viewModel.currentChain == .all
    self.navigationController.showLoadingHUD()
    self.loadBalanceCoordinator?.restartNewSession(self.session)
    self.investCoordinator?.appCoordinatorSwitchAddress()
    
    KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.overviewTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    
    self.doLogin { _ in }
    
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
  
  func onRemoveWallet(wallet: KWallet) {
    if wallet.id == session.address.walletID {
      NonceCache.shared.resetNonce(wallet: wallet)
      walletCache.unmarkWalletBackedUp(walletID: wallet.id)
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
