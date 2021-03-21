// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import IQKeyboardManager
import BigInt
import Moya
import OneSignal
import TwitterKit

class KNAppCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  let window: UIWindow
  internal var keystore: Keystore
  var coordinators: [Coordinator] = []
  internal var session: KNSession!
  internal var currentWallet: Wallet!
  internal var loadBalanceCoordinator: KNLoadBalanceCoordinator?

  internal var exchangeCoordinator: KNExchangeTokenCoordinator?
//  internal var balanceTabCoordinator: KNBalanceTabCoordinator?
  internal var overviewTabCoordinator: OverviewCoordinator?
  internal var settingsCoordinator: KNSettingsCoordinator?
  internal var earnCoordinator: EarnCoordinator?
  internal var investCoordinator: InvestCoordinator?

  internal var tabbarController: KNTabBarController!
  internal var transactionStatusCoordinator: KNTransactionStatusCoordinator!

  lazy var splashScreenCoordinator: KNSplashScreenCoordinator = {
    return KNSplashScreenCoordinator()
  }()

  lazy var authenticationCoordinator: KNPasscodeCoordinator = {
    let passcode = KNPasscodeCoordinator(type: .authenticate(isUpdating: false))
    passcode.delegate = self
    return passcode
  }()

  lazy var landingPageCoordinator: KNLandingPageCoordinator = {
    let coordinator = KNLandingPageCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var addWalletCoordinator: KNAddNewWalletCoordinator = {
    let coordinator = KNAddNewWalletCoordinator(keystore: self.session.keystore)
    coordinator.delegate = self
    return coordinator
  }()

  internal var promoCodeCoordinator: KNPromoCodeCoordinator?

  init(
    navigationController: UINavigationController = UINavigationController(),
    window: UIWindow,
    keystore: Keystore) {
    self.navigationController = navigationController
    self.window = window
    self.keystore = keystore
    super.init()
    self.window.rootViewController = self.navigationController
    self.window.makeKeyAndVisible()
  }

  deinit {
    self.removeInternalObserveNotification()
    self.removeObserveNotificationFromSession()
  }

  func start() {
    self.addMissingWalletObjects()
    KNSupportedTokenStorage.shared.addLocalSupportedTokens()
    guard !self.showBackupWalletIfNeeded() else {
      return
    }
    self.startLandingPageCoordinator()
    self.startFirstSessionIfNeeded()
    self.addInternalObserveNotification()
    self.setPredefineValues()
    if UIDevice.isIphone5 {
      self.navigationController.displaySuccess(title: "", message: "We are not fully supported iphone5 or small screen size. Some UIs might be broken.")
    }
  }

  fileprivate func setPredefineValues() {
    UserDefaults.standard.set(false, forKey: Constants.kisShowQuickTutorialForLongPendingTx)
  }

  fileprivate func addMissingWalletObjects() {
    let walletObjects = self.keystore.wallets.filter {
      return KNWalletStorage.shared.get(forPrimaryKey: $0.address.description) == nil
    }.map { return KNWalletObject(address: $0.address.description) }
    KNWalletStorage.shared.add(wallets: walletObjects)
  }

  fileprivate func startLandingPageCoordinator() {
    self.addCoordinator(self.landingPageCoordinator)
    self.landingPageCoordinator.start()
  }

  fileprivate func startFirstSessionIfNeeded() {
    // For security, should always have passcode protection when user has imported wallets
    if let wallet = self.keystore.recentlyUsedWallet ?? self.keystore.wallets.first,
      KNPasscodeUtil.shared.currentPasscode() != nil {
      if case .real(let account) = wallet.type {
        // Check case if password for account is not exist, cancel start new session
        guard let _ =  keystore.getPassword(for: account) else {
           return
        }
      }
      self.startNewSession(with: wallet)
    }
  }

  fileprivate func showBackupWalletIfNeeded() -> Bool {
    guard let currentWallet = self.keystore.recentlyUsedWallet else { return false }
    guard let _ = KNWalletStorage.shared.wallets.first(where: { (object) -> Bool in
      return object.isBackedUp == false && object.address.lowercased() == currentWallet.address.description.lowercased()
    }) else {
      return false
    }
    if self.keystore.wallets.count > 1 {
      let alert = KNPrettyAlertController(
        title: nil,
        message: "Wallet.must.be.backed.up".toBeLocalised(),
        secondButtonTitle: "backup".toBeLocalised(),
        firstButtonTitle: "Later".toBeLocalised(),
        secondButtonAction: {
          self.tabbarController = nil
          self.landingPageCoordinator.updateNewWallet(wallet: currentWallet)
          self.addCoordinator(self.landingPageCoordinator)
          self.landingPageCoordinator.start()
        },
        firstButtonAction: nil)
      self.navigationController.present(alert, animated: true, completion: {
      })
      return false
    } else {
      self.landingPageCoordinator.updateNewWallet(wallet: currentWallet)
      self.addCoordinator(self.landingPageCoordinator)
      self.landingPageCoordinator.start()
      return true
    }
  }
  
  func sendRefCode(_ code: String) {
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    if case .real(let account) = self.session.wallet.type {
      let result = self.session.keystore.signMessage(sendData, for: account)
      switch result {
      case .success(let signedData):
        let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
        provider.request(.registerReferrer(address: self.session.wallet.address.description, referralCode: code, signature: signedData.hexEncoded)) { (result) in
          if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
            if let isSuccess = json["success"] as? Bool, isSuccess {
              self.tabbarController.showTopBannerView(message: "Success register referral code")
            } else if let error = json["error"] as? String {
              self.tabbarController.showTopBannerView(message: error)
            } else {
              self.tabbarController.showTopBannerView(message: "Fail to register referral code")
            }
          }
        }
      case .failure(let error):
        print("[Send ref code] \(error.localizedDescription)")
      }
    }
  }
}

// Application state
extension KNAppCoordinator {
  func appDidFinishLaunch() {
    self.splashScreenCoordinator.start()
    self.authenticationCoordinator.start(isLaunch: true)
    IQKeyboardManager.shared().isEnabled = true
    IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    KNSession.resumeInternalSession()
    TWTRTwitter.sharedInstance().start(
      withConsumerKey: KNEnvironment.default.twitterConsumerID,
      consumerSecret: KNEnvironment.default.twitterSecretKey
    )
    if !KNAppTracker.hasLoggedUserOutWithNativeSignIn() {
      if IEOUserStorage.shared.user != nil {
        self.navigationController.showWarningTopBannerMessage(
          with: NSLocalizedString("session.expired", value: "Session expired", comment: ""),
          message: NSLocalizedString("your.session.has.expired.sign.in.to.continue", value: "Your session has expired, please sign in again to continue", comment: ""),
          time: 1.5
        )
      }
      KNAppTracker.updateHasLoggedUserOutWithNativeSignIn()
    }

    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedStringKey.foregroundColor: UIColor.Kyber.tabbarNormal, NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 10)],
      for: .normal
    )
    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWYellow],
      for: .selected
    )

    if isDebug {
      KNAppTracker.updateWonderWhyOrdersNotFilled(isRemove: true)
      KNAppTracker.updateCancelOpenOrderTutorial(isRemove: true)
    }

    // reset history filter every time open app
    KNAppTracker.removeHistoryFilterData()
    KNAppTracker.updateShouldShowUserTranserConsentPopUp(true)
  }

  func appDidBecomeActive() {
    KNSession.pauseInternalSession()
    KNSession.resumeInternalSession()
    self.loadBalanceCoordinator?.resume()
    KNVersionControlManager.shouldShowUpdateApp { (shouldShow, isForced, title, subtitle) in
      if !shouldShow { return }
      if !isForced {
        let alert = KNPrettyAlertController(
          title: (title ?? "Update available!").toBeLocalised(),
          message: (subtitle ?? "New version is available for updating. Click to update now!").toBeLocalised(),
          secondButtonTitle: "Update".toBeLocalised(),
          firstButtonTitle: "cancel".toBeLocalised(),
          secondButtonAction: {
            KNCrashlyticsUtil.logCustomEvent(
              withName: "update_alert_update_tapped",
              customAttributes: nil
            )
            DispatchQueue.main.async {
              self.navigationController.openSafari(with: "https://apps.apple.com/us/app/id1521778973")
            }
          }, firstButtonAction: {
            KNCrashlyticsUtil.logCustomEvent(
              withName: "update_alert_cancel_tapped",
              customAttributes: nil
            )
          }
        )
        DispatchQueue.main.async {
          self.navigationController.present(alert, animated: true, completion: nil)
        }
      } else {
        KNCrashlyticsUtil.logCustomEvent(
          withName: "force_update",
          customAttributes: ["cur_version": Bundle.main.versionNumber ?? ""]
        )
        let alert = KNPrettyAlertController(
          title: (title ?? "Update available!").toBeLocalised(),
          message: (subtitle ?? "New version is available for updating. Click to update now!").toBeLocalised(),
          secondButtonTitle: nil,
          firstButtonTitle: "Update".toBeLocalised(),
          secondButtonAction: nil,
          firstButtonAction: {
            KNCrashlyticsUtil.logCustomEvent(
              withName: "update_alert_update_tapped",
              customAttributes: nil
            )
            DispatchQueue.main.async {
              self.navigationController.openSafari(with: "https://apps.apple.com/us/app/id1521778973")
            }
          }
        )
        DispatchQueue.main.async {
          self.navigationController.present(alert, animated: true, completion: nil)
        }
      }
    }
    KNNotificationUtil.postNotification(for: "viewDidBecomeActive")
  }

  func appWillEnterForeground() {
    if KNAppTracker.shouldShowAuthenticate() {
      self.authenticationCoordinator.start()
    }
//    self.balanceTabCoordinator?.appCoordinatorWillEnterForeground()
    self.exchangeCoordinator?.appCoordinatorWillEnterForeground()
  }

  func appDidEnterBackground() {
    self.splashScreenCoordinator.stop()
    KNSession.pauseInternalSession()
    self.loadBalanceCoordinator?.pause()
//    self.balanceTabCoordinator?.appCoordinatorDidEnterBackground()
    self.exchangeCoordinator?.appCoordinatorDidEnterBackground()
  }

  func appWillTerminate() {
//    self.balanceTabCoordinator?.appCoordinatorWillTerminate()
    self.exchangeCoordinator?.appCoordinatorWillTerminate()
  }

  func appDidReceiveLocalNotification(transactionHash: String) {
    let urlString = KNEnvironment.default.etherScanIOURLString + "tx/\(transactionHash)"
    if self.transactionStatusCoordinator != nil {
      self.transactionStatusCoordinator.rootViewController?.openSafari(with: urlString)
    } else {
      guard let url = URL(string: urlString) else { return }
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  func appDidReceiverOneSignalPushNotification(notification: OSNotification?) {
  }

  func appDidReceiverOneSignalPushNotification(result: OSNotificationOpenedResult?) {
    if let noti = result?.notification,
      let data = noti.payload.additionalData, let notiID = data["notification_id"] as? Int {
      KNNotificationCoordinator.shared.markAsRead(ids: [notiID]) { _ in }
    }

    if let noti = result?.notification,
      let data = noti.payload.additionalData,
      let type = data["type"] as? String, type == "alert_price", self.tabbarController != nil {
      self.handlePriceAlertPushNotification(noti)
      return
    }
    if let noti = result?.notification,
      let data = noti.payload.additionalData,
      let type = data["type"] as? String, type == "limit_order", self.tabbarController != nil {
      self.handleLimitOrderNotification(noti)
      return
    }
    if let noti = result?.notification,
       let data = noti.payload.additionalData,
      let type = data["type"] as? String, type == "swap", self.tabbarController != nil {
      self.handleOpenKyberSwapPushNotification(noti, isPriceAlert: false)
      return
    }
    if let noti = result?.notification,
       let data = noti.payload.additionalData,
      let type = data["type"] as? String, type == "new_listing",
      self.tabbarController != nil, let token = data["token"] as? String {
      self.tabbarController.selectedIndex = 1
      self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: "ETH", to: token)
      return
    }
    if let data = result?.notification.payload.additionalData,
      let urlString = data["link"] as? String, let url = URL(string: urlString) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
      return
    }
    if let noti = result?.notification,
      let data = noti.payload.additionalData,
      let type = data["type"] as? String, type == "balance", self.tabbarController != nil {
      self.handleOpenBalanceTabPushNotification(noti)
      return
    }
    guard let payload = result?.notification.payload else { return }
    let title = payload.title
    let body = payload.body
    let alertController = KNPrettyAlertController(
      title: title,
      message: body ?? "",
      secondButtonTitle: nil,
      firstButtonTitle: "OK".toBeLocalised(),
      secondButtonAction: nil,
      firstButtonAction: nil
    )
    DispatchQueue.main.async {
      self.navigationController.present(alertController, animated: true, completion: nil)
    }
  }

  fileprivate func handleOpenKyberSwapPushNotification(_ notification: OSNotification, isPriceAlert: Bool = true) {
    self.tabbarController.selectedIndex = 1
    if isPriceAlert {
      let base = notification.payload.additionalData["base"] as? String ?? ""
      let from: String = {
        if base == "USD" { return "ETH" }
        return notification.payload.additionalData["token"] as? String ?? ""
      }()
      let to = base == "USD" ? "KNC" : "ETH"
      self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
      return
    }
    let from: String = notification.payload.additionalData["from"] as? String ?? ""
    let to: String = notification.payload.additionalData["to"] as? String ?? ""
    self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
  }

  fileprivate func handleOpenBalanceTabPushNotification(_ notification: OSNotification) {
    self.tabbarController.selectedIndex = 0
    let currency = notification.payload.additionalData["currency"] as? String ?? KNAppTracker.getCurrencyType().rawValue
    let currencyType = KWalletCurrencyType(rawValue: currency) ?? KNAppTracker.getCurrencyType()
//    self.balanceTabCoordinator?.appCoordinatorBalanceSorted(with: currencyType)
  }

  fileprivate func handlePriceAlertPushNotification(_ notification: OSNotification) {
    if notification.payload.additionalData == nil { return }
    let view = "kyberswap" // we only open kyberswap for now
    let token = notification.payload.additionalData["token"] as? String ?? ""
    if view == "token_chart" {
      self.tabbarController.selectedIndex = 0
//      self.balanceTabCoordinator?.appCoordinatorOpenTokenChart(for: token)
    } else if view == "balance" {
      self.tabbarController.selectedIndex = 0
//      self.balanceTabCoordinator?.appCoordinatorDidUpdateNewSession(self.session, resetRoot: true)
    } else if view == "kyberswap" {
      self.handleOpenKyberSwapPushNotification(notification, isPriceAlert: true)
    }
    let alertID = notification.payload.additionalData["alert_id"] as? Int ?? -1
    guard let alert = KNAlertStorage.shared.alerts.first(where: { $0.id == alertID }) else {
      // reload list alerts
      KNPriceAlertCoordinator.shared.startLoadingListPriceAlerts(nil)
      return
    }
    let action = notification.payload.additionalData["action"] as? String ?? NSLocalizedString("ok", value: "OK", comment: "")
    let desc = notification.payload.body ?? ""
    let controller = KNNotificationAlertPopupViewController(
      alert: alert,
      actionButtonTitle: action,
      descriptionText: desc
    )
    controller.loadViewIfNeeded()
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .crossDissolve
    self.navigationController.present(controller, animated: true, completion: nil)
  }

  fileprivate func handleLimitOrderNotification(_ notification: OSNotification) {
    guard let data = notification.payload.additionalData else { return }
    let orderID = data["order_id"] as? Int ?? -1
    let srcToken = data["src_token"] as? String ?? ""
    let destToken = data["dst_token"] as? String ?? ""
    let rate: Double = {
      if let value = data["min_rate"] as? Double { return value }
      if let valueStr = data["min_rate"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let amount: Double = {
      if let value = data["src_amount"] as? Double { return value }
      if let valueStr = data["src_amount"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let fee: Double = {
      if let value = data["fee"] as? Double { return value }
      if let valueStr = data["fee"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let transferFee: Double = {
      if let value = data["transfer_fee"] as? Double { return value }
      if let valueStr = data["transfer_fee"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let sender = data["sender"] as? String ?? ""
    let createdDate: Double = {
      if let value = data["created_at"] as? Double { return value }
      if let valueStr = data["created_at"] as? String, let value = Double(valueStr) {
        return value
      }
      return Date().timeIntervalSince1970
    }()
    let updatedDate: Double = {
      if let value = data["updated_at"] as? Double { return value }
      if let valueStr = data["updated_at"] as? String, let value = Double(valueStr) {
        return value
      }
      return Date().timeIntervalSince1970
    }()
    let receive = data["receive"] as? Double ?? 0.0
    let txHash = data["tx_hash"] as? String ?? ""

    let order = KNOrderObject(
      id: orderID,
      from: srcToken,
      to: destToken,
      amount: amount,
      price: rate,
      fee: fee + transferFee,
      nonce: "",
      sender: sender,
      sideTrade: data["side_trade"] as? String,
      createdDate: createdDate,
      filledDate: updatedDate,
      messages: "",
      txHash: txHash,
      stateValue: KNOrderState.filled.rawValue,
      actualDestAmount: receive
    )
    let controller = KNLimitOrderDetailsPopUp(order: order)
    controller.loadViewIfNeeded()
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .crossDissolve
    if self.tabbarController != nil { self.tabbarController.selectedIndex = 2 }
    self.navigationController.present(controller, animated: true, completion: nil)
  }
}
