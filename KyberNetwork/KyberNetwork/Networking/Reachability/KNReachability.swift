// Copyright SIX DAY LLC. All rights reserved.

import Alamofire
import NotificationCenter

class KNReachability: NSObject {

  static let kNetworkReachableNotificationKey: String = "kNetworkReachableNotificationKey"
  static let kNetworkUnreachableNotificationKey: String = "kNetworkUnreachableNotificationKey"

  static let shared = KNReachability()
  let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")

  fileprivate(set) var previousStatus: NetworkReachabilityManager.NetworkReachabilityStatus = .unknown
  fileprivate var isListening: Bool = false

  func startNetworkReachabilityObserver() {
    if self.isListening { return }
    self.isListening = true
    self.reachabilityManager?.startListening(onUpdatePerforming: { status in
      switch status {
      case .reachable(let type):
        if type == .ethernetOrWiFi {
          NSLog("Network is reachable over Wifi")
        } else {
          NSLog("Network is reachable over WWAN")
        }
        let notiName = Notification.Name(rawValue: KNReachability.kNetworkReachableNotificationKey)
        NotificationCenter.default.post(name: notiName, object: type)
      case .unknown:
        NSLog("Network reachability is unknown")
        if self.previousStatus != .unknown {
          self.showWarningTopBannerMessage(
            with: "",
            message: NSLocalizedString("please.check.your.internet.connection", value: "Please check your internet connection", comment: "")
          )
        }
        let notiName = Notification.Name(rawValue: KNReachability.kNetworkUnreachableNotificationKey)
        NotificationCenter.default.post(name: notiName, object: nil)
      case .notReachable:
        NSLog("Network is not reachable.")
        if self.previousStatus != .notReachable {
          self.showWarningTopBannerMessage(
            with: "",
            message: NSLocalizedString("please.check.your.internet.connection", value: "Please check your internet connection", comment: "")
          )
        }
        let notiName = Notification.Name(rawValue: KNReachability.kNetworkUnreachableNotificationKey)
        NotificationCenter.default.post(name: notiName, object: nil)
      }
      self.previousStatus = status
    })
//    self.reachabilityManager?.startListening()
  }

  func stopNetworkReachabilityObserver() {
    if !self.isListening { return }
    self.isListening = false
    self.reachabilityManager?.stopListening()
  }
}
