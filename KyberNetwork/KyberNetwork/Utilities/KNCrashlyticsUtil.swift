// Copyright SIX DAY LLC. All rights reserved.

import FirebaseAnalytics
import Firebase
import FirebasePerformance

class KNCrashlyticsUtil {

  static func logCustomEvent(withName name: String, customAttributes: [String: Any]?) {
//    if !isDebug {
      Analytics.logEvent(name, parameters: customAttributes)
//    }
  }
  
  static func updateUserId(userId: String) {
    Analytics.setUserID(userId)
  }
}

class PerformanceUtil {
  static func createTrace(_ name: String) -> Trace? {
    guard FirebaseApp.app() != nil else {
      return nil
    }
    return Performance.startTrace(name: name)
  }
}
