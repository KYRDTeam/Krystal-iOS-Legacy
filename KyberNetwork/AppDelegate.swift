// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Sentry
import Firebase
import OneSignal
import AppTrackingTransparency

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
    
    // promptForPushNotifications will show the native iOS notification permission prompt.
    // We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 8)
    OneSignal.promptForPushNotifications(userResponse: { accepted in
      print("User accepted notifications: \(accepted)")
    })
    
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { (status) in
        if status == .authorized {
          FirebaseApp.configure()
        }
      }
    } else {
      FirebaseApp.configure()
    }
    
    KNCrashlyticsUtil.logCustomEvent(withName: "krystal_open_app_event", customAttributes: nil)
    
    SentrySDK.start { options in
      options.dsn = KNSecret.sentryURL
      options.debug = true // Enabled debug when first installing is always helpful
      options.tracesSampleRate = 1.0
      options.environment = KNEnvironment.default.displayName
    }

    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
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
    return true
  }

  // Respond to URI scheme links
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
//    GIDSignIn.sharedInstance().handle(url)
    return true
  }

  // Respond to Universal Links
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    return true
  }
}
