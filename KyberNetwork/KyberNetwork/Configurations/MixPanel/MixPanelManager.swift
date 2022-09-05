//
//  MixPanelManager.swift
//  KyberNetwork
//
//  Created by Com1 on 05/04/2022.
//
import Mixpanel
import Foundation
import AppTrackingTransparency

let mixPanelProjectToken = KNEnvironment.default == .production ? KNSecret.prodMixPannelKey : KNSecret.devMixPannelKey

class MixPanelManager {
  
  
  static let shared = MixPanelManager()
  
  func configClient() {
    Mixpanel.initialize(token: mixPanelProjectToken)
    
  }
  
  func setDistintID(_ id: String) {
    Mixpanel.getInstance(name: mixPanelProjectToken)?.distinctId = id
  }

  func updateWalletAddress(address: String) {
    var shouldConfigTrackingTool = true
    if #available(iOS 14, *) {
      let status = ATTrackingManager.trackingAuthorizationStatus
      shouldConfigTrackingTool = status == .authorized
    }
    guard shouldConfigTrackingTool else { return }
    Mixpanel.mainInstance().track(event: "wallet_address", properties: [
      "user-id": address
    ])
  }
  
  static func track(_ event: String, properties: Properties? = nil) {
    var shouldConfigTrackingTool = true
    if #available(iOS 14, *) {
      let status = ATTrackingManager.trackingAuthorizationStatus
      shouldConfigTrackingTool = status == .authorized
    }
    guard shouldConfigTrackingTool else { return }
    Mixpanel.mainInstance().track(event: event, properties: properties)
  }
}
