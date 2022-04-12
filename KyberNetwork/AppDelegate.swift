// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Sentry
import Firebase
import OneSignal
import AppTrackingTransparency
import WalletConnectSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
  var window: UIWindow?
  var coordinator: KNAppCoordinator!

  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    do {
      let keystore = try EtherKeystore()
      coordinator = KNAppCoordinator(window: window!, keystore: keystore)
      coordinator.start()
      coordinator.appDidFinishLaunch()
    } catch {
      print("EtherKeystore init issue.")
    }
    KNReachability.shared.startNetworkReachabilityObserver()

    // Remove this method to stop OneSignal Debugging
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
    
    // promptForPushNotifications will show the native iOS notification permission prompt.
    // We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 8)
    OneSignal.promptForPushNotifications(userResponse: { accepted in
      print("User accepted notifications: \(accepted)")
    })

    KNCrashlyticsUtil.logCustomEvent(withName: "krystal_open_app_event", customAttributes: nil)
    return true
  }
  
  fileprivate func setupSentry() {
    SentrySDK.start { options in
      options.dsn = KNSecret.sentryURL
      options.debug = true // Enabled debug when first installing is always helpful
      options.tracesSampleRate = 1.0
      options.environment = KNEnvironment.default.displayName
    }
  }

  func applicationWillResignActive(_ application: UIApplication) {
  }

  fileprivate func requestAcceptToolTrackingIfNeeded() {
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
    MixPanelManager.shared.configClient()
    if KNEnvironment.default == .production {
      FirebaseApp.configure()
    } else {
      let filePath = Bundle.main.path(forResource: "GoogleService-Info-Dev", ofType: "plist")
      guard let fileopts = FirebaseOptions(contentsOfFile: filePath!) else {
        return
      }
      FirebaseApp.configure(options: fileopts)
    }
    guard !SentrySDK.isEnabled else { return }
    self.setupSentry()
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    coordinator.appDidBecomeActive()
    KNReachability.shared.startNetworkReachabilityObserver()
    self.requestAcceptToolTrackingIfNeeded()
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
    } else {
      self.coordinator.overviewTabCoordinator?.navigationController.openSafari(with: url)
    }
    return true
  }
}
