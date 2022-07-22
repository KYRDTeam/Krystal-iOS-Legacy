// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Sentry
import Firebase
import OneSignal
import AppTrackingTransparency
import WalletConnectSwift
import IQKeyboardManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
  var window: UIWindow?
  var coordinator: KNAppCoordinator!
  
  static var shared: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
  }
  
  static var session: KNSession {
    return shared.coordinator.session
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    setupKeyboard()
    do {
      let keystore = try EtherKeystore()
      coordinator = KNAppCoordinator(window: window!, keystore: keystore)
      coordinator.start()
      coordinator.appDidFinishLaunch()
    } catch {
      print("EtherKeystore init issue.")
    }
    KNReachability.shared.startNetworkReachabilityObserver()
    
    setupFirebase()
    setupOneSignal(launchOptions)
    
    // promptForPushNotifications will show the native iOS notification permission prompt.
    // We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 8)
    OneSignal.promptForPushNotifications(userResponse: { accepted in
      print("User accepted notifications: \(accepted)")
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.requestAcceptTrackingFirebaseIfNeeded()
      }
    })
    KNCrashlyticsUtil.logCustomEvent(withName: "krystal_open_app_event", customAttributes: nil)
    return true
  }
  
  func setupOneSignal(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
    // OneSignal initialization
    OneSignal.initWithLaunchOptions(launchOptions)
    OneSignal.setAppId(KNEnvironment.default.notificationAppID)
    let notificationOpenedBlock: OSNotificationOpenedBlock = { result in
        // This block gets called when the user reacts to a notification received
        let notification: OSNotification = result.notification
        if let launchURL = notification.launchURL, let url = URL(string: launchURL), let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
          var parameters: [String: String] = [:]
          components.queryItems?.forEach({ element in
            parameters[element.name] = element.value
          })
          if components.path == "/swap" {
            self.coordinator.exchangeCoordinator?.appCoordinatorReceivedTokensSwapFromUniversalLink(srcTokenAddress: parameters["srcAddress"], destTokenAddress: parameters["destAddress"], chainIdString: parameters["chainId"])
          } else {
            self.coordinator.overviewTabCoordinator?.navigationController.openSafari(with: url)
          }
        }
    }
    OneSignal.setNotificationOpenedHandler(notificationOpenedBlock)
  }
  
  fileprivate func setupSentry() {
    SentrySDK.start { options in
      options.dsn = KNSecret.sentryURL
      options.debug = true // Enabled debug when first installing is always helpful
      options.tracesSampleRate = KNEnvironment.default == .production ? 0.2 : 1.0
      options.environment = KNEnvironment.default.displayName
    }
  }

  fileprivate func requestAcceptTrackingFirebaseIfNeeded() {
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { (status) in
        if status == .authorized {
          self.setupTrackingTools()
        }
      }
    } else {
      self.setupTrackingTools()
    }
  }
  
  fileprivate func setupTrackingTools() {
    var shouldConfigTrackingTool = true
    if #available(iOS 14, *) {
      let status = ATTrackingManager.trackingAuthorizationStatus
      shouldConfigTrackingTool = status == .authorized
    }
    guard shouldConfigTrackingTool else { return }
    MixPanelManager.shared.configClient()
    guard !SentrySDK.isEnabled else { return }
    self.setupSentry()
  }
  
  fileprivate func setupFirebase() {
    if KNEnvironment.default == .production {
      FirebaseApp.configure()
    } else {
      let filePath = Bundle.main.path(forResource: "GoogleService-Info-Dev", ofType: "plist")
      guard let fileopts = FirebaseOptions(contentsOfFile: filePath!) else {
        return
      }
      FirebaseApp.configure(options: fileopts)
    }
  }
  
  func setupKeyboard() {
    IQKeyboardManager.shared().isEnabled = true
    IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    
    let disabledToolbarClasses = [
      KNImportSeedsViewController.self,
      KNImportPrivateKeyViewController.self,
      KNImportJSONViewController.self
    ]
    disabledToolbarClasses.forEach { Class in
      IQKeyboardManager.shared().disabledToolbarClasses.add(Class)
    }
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    coordinator.appDidBecomeActive()
    KNReachability.shared.startNetworkReachabilityObserver()
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    coordinator.appDidEnterBackground()
    KNReachability.shared.stopNetworkReachabilityObserver()
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    self.coordinator.appWillEnterForeground()
  }

  func applicationWillTerminate(_ application: UIApplication) {
    self.coordinator.appWillTerminate()
  }

  func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
    if extensionPointIdentifier == UIApplication.ExtensionPointIdentifier.keyboard {
      return false
    }
    return true
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if let scheme = url.scheme,
       scheme.localizedCaseInsensitiveCompare("krystalwallet") == .orderedSame {
      var parameters: [String: String] = [:]
      URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
        parameters[$0.name] = $0.value
      }
      if let uri = parameters["uri"] {
        self.coordinator.overviewTabCoordinator?.appCoordinatorReceiveWallectConnectURI(uri)
      }
    }

    return true
  }

  // Respond to URI scheme links
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
//    GIDSignIn.sharedInstance().handle(url)
    return true
  }

  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
          return false
    }
    var parameters: [String: String] = [:]
    components.queryItems?.forEach({ element in
      parameters[element.name] = element.value
    })
    
    if components.path == "/swap" {
      self.coordinator.exchangeCoordinator?.appCoordinatorReceivedTokensSwapFromUniversalLink(srcTokenAddress: parameters["srcAddress"], destTokenAddress: parameters["destAddress"], chainIdString: parameters["chainId"])
    } else if components.path == "/token" {
      self.coordinator.overviewTabCoordinator?.navigationController.tabBarController?.selectedIndex = 0
      self.coordinator.overviewTabCoordinator?.navigationController.popToRootViewController(animated: false)
      let supportedChainIds = ChainType.getAllChain().map { return $0.getChainId() }
      if let chainId = Int(parameters["chainId"] ?? "0"), supportedChainIds.contains(chainId) {
        self.coordinator.overviewTabCoordinator?.appCoordinatorReceivedTokensDetailFromUniversalLink(tokenAddress: parameters["address"] ?? "", chainIdString: parameters["chainId"])
      } else {
        let errorVC = ErrorViewController()
        errorVC.modalPresentationStyle = .fullScreen
        self.coordinator.overviewTabCoordinator?.navigationController.present(errorVC, animated: false)
      }
        
    } else {
      self.coordinator.overviewTabCoordinator?.navigationController.openSafari(with: url)
    }
    return true
  }
}
