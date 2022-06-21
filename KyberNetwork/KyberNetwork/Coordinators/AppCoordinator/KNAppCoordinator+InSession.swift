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
    KNCrashlyticsUtil.updateUserId(userId: address.addressString)
    self.session = KNSession(address: address)
    self.session.startSession()
    
    DispatchQueue.global(qos: .background).async {
      _ = KNSupportedTokenStorage.shared
      _ = BalanceStorage.shared
      _ = KNTrackerRateStorage.shared
    }
    
    FeatureFlagManager.shared.configClient(session: self.session)
    self.loadBalanceCoordinator?.exit()
    self.loadBalanceCoordinator = nil
    self.loadBalanceCoordinator = KNLoadBalanceCoordinator()
    self.loadBalanceCoordinator?.resume()

    self.tabbarController = KNTabBarController()
    
    let overviewCoordinator = OverviewCoordinator()
    self.addCoordinator(overviewCoordinator)
    overviewCoordinator.delegate = self
    overviewCoordinator.start()
    self.overviewTabCoordinator = overviewCoordinator

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

    self.tabbarController.viewControllers = [
      self.overviewTabCoordinator!.navigationController,
      self.exchangeCoordinator!.navigationController,
      self.investCoordinator!.navigationController,
      self.earnCoordinator!.navigationController,
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
    KNPasscodeUtil.shared.deletePasscode()
    self.landingPageCoordinator.navigationController.popToRootViewController(animated: false)

    self.loadBalanceCoordinator?.exit()
    self.loadBalanceCoordinator = nil

    self.walletManager.removeAll()
    
    self.session.stopSession()
    self.session = nil

    self.navigationController.popToRootViewController(animated: true)

    self.exchangeCoordinator?.stop()
    self.exchangeCoordinator = nil
    self.settingsCoordinator?.stop()
    self.settingsCoordinator = nil
    self.tabbarController = nil
  }

  func restartSession(address: KAddress, showLoading: Bool = true) {
    if showLoading { self.navigationController.displayLoading() }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.session.switchAddress(address: address)
      FeatureFlagManager.shared.configClient(session: self.session)
      self.loadBalanceCoordinator?.restartNewSession(self.session)
      self.investCoordinator?.appCoordinatorSwitchAddress()

      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
      self.overviewTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate()

      self.doLogin { _ in }
      self.navigationController.hideLoading()
      
      NotificationCenter.default.post(
        name: Notification.Name(kAppDidUpdateNewSession),
        object: nil,
        userInfo: ["session": self.session]
      )
  
      MixPanelManager.shared.updateWalletAddress(address: address.addressString)
      KNCrashlyticsUtil.updateUserId(userId: address.addressString)
    }
    
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
      navigationController: self.navigationController,
      keystore: self.keystore
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
