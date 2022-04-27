// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import IQKeyboardManager
import BigInt
import Moya
//import OneSignal
//import TwitterKit

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
  internal var rewardCoordinator: RewardCoordinator?
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
  var isFirstLoad: Bool = true
  var isFirstUpdateChain: Bool = true

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
      return KNWalletStorage.shared.get(forPrimaryKey: $0.addressString) == nil
    }.map { return KNWalletObject(address: $0.addressString) }
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

  @discardableResult
  func showBackupWalletIfNeeded() -> Bool {
    guard let currentWallet = self.keystore.recentlyUsedWallet else { return false }
    guard let walletObj = KNWalletStorage.shared.wallets.first(where: { (object) -> Bool in
      return object.isBackedUp == false && object.address.lowercased() == currentWallet.addressString && !object.isWatchWallet
    }) else {
      return false
    }
    if self.keystore.wallets.count >= 1 {
      if case .real(let account) = self.session.wallet.type {
        let result = self.session.keystore.exportPrivateKey(account: account)
        switch result {
        case .success(_):
          let controller = OverviewWarningBackupViewController {
            self.tabbarController = nil
            self.landingPageCoordinator.updateNewWallet(wallet: currentWallet)
            self.addCoordinator(self.landingPageCoordinator)
            self.landingPageCoordinator.start()
          } alreadyAction: {
            let walletObject = walletObj.clone()
            walletObject.isBackedUp = true
            KNWalletStorage.shared.add(wallets: [walletObject])
          }
          self.overviewTabCoordinator?.navigationController.present(controller, animated: true, completion: {
          })
        default:
          let walletObject = walletObj.clone()
          walletObject.isWatchWallet = true
          KNWalletStorage.shared.add(wallets: [walletObject])
        }
      } else {
        let walletObject = walletObj.clone()
        walletObject.isWatchWallet = true
        KNWalletStorage.shared.add(wallets: [walletObject])
      }
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
        provider.request(.registerReferrer(address: self.session.wallet.addressString, referralCode: code, signature: signedData.hexEncoded)) { (result) in
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
  
  func doLogin(_ completion: @escaping (Bool) -> Void) {
    guard case .real(let account) = self.session.wallet.type else {
      return
    }
    DispatchQueue.global(qos: .background).async {
      let timestamp = Int(NSDate().timeIntervalSince1970)
      let message = "\(self.session.wallet.addressString)_\(timestamp)"
      let data = Data(message.utf8)
      let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
      let sendData = prefix + data
      let result = self.session.keystore.signMessage(sendData, for: account)
      switch result {
      case .success(let signedData):
        let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
        provider.request(.login(address: self.session.wallet.addressString, timestamp: timestamp, signature: signedData.hexEncoded)) { (result) in
          if case .success(let resp) = result {
            print(resp.debugDescription)
            let decoder = JSONDecoder()
            do {
              let data = try decoder.decode(LoginToken.self, from: resp.data)
              Storage.store(data, as: self.session.wallet.addressString + Constants.loginTokenStoreFileName)
              completion(true)
            } catch let error {
              print("[Login][Error] \(error.localizedDescription)")
              completion(false)
            }
          } else {
            completion(false)
          }
        }
      case .failure(let error):
        self.doLogin(completion)
      }
    }
  }
}

// Application state
extension KNAppCoordinator {
  func appDidFinishLaunch() {
    self.splashScreenCoordinator.start()
    self.authenticationCoordinator.start()
    IQKeyboardManager.shared().isEnabled = true
    IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    KNSession.resumeInternalSession()

    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedString.Key.foregroundColor: UIColor.Kyber.tabbarNormal, NSAttributedString.Key.font: UIFont.Kyber.latoRegular(with: 10)],
      for: .normal
    )
    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWYellow],
      for: .selected
    )

    if isDebug {
      KNAppTracker.updateWonderWhyOrdersNotFilled(isRemove: true)
      KNAppTracker.updateCancelOpenOrderTutorial(isRemove: true)
    }

    // reset history filter every time open app
    KNAppTracker.removeHistoryFilterData()
    KNAppTracker.updateShouldShowUserTranserConsentPopUp(true)

    FeatureFlagManager.shared.configClient(session: session)
  }

  func appDidBecomeActive() {
    KNSession.pauseInternalSession()
    KNSession.resumeInternalSession()
    self.loadBalanceCoordinator?.resume()
    KNNotificationUtil.postNotification(for: "viewDidBecomeActive")
  }

  func appWillEnterForeground() {
    if KNAppTracker.shouldShowAuthenticate() {
      self.authenticationCoordinator.start()
    }
  }

  func appDidEnterBackground() {
    self.splashScreenCoordinator.stop()
    KNSession.pauseInternalSession()
    self.loadBalanceCoordinator?.pause()
  }

  func appWillTerminate() {
  }

  func appDidReceiveLocalNotification(transactionHash: String) {
    let urlString = KNGeneralProvider.shared.customRPC.etherScanEndpoint + "tx/\(transactionHash)"
    self.tabbarController.openSafari(with: urlString)
  }

}
