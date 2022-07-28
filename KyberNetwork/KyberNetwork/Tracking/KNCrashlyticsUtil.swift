// Copyright SIX DAY LLC. All rights reserved.

import FirebaseAnalytics
import Firebase
import FirebasePerformance

class Tracker {
  
  static func track(event: TrackingEvent, customAttributes: [String: Any]? = nil) {
    Analytics.logEvent(event.rawValue, parameters: customAttributes)
  }
  
  static func track(eventName: String, customAttributes: [String: Any]? = nil) {
    Analytics.logEvent(eventName, parameters: customAttributes)
  }
  
  static func updateUserID(_ userID: String) {
    Analytics.setUserID(userID)
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
