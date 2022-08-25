//
//  MixPanelManager.swift
//  KyberNetwork
//
//  Created by Com1 on 05/04/2022.
//
import Mixpanel
import Foundation
import AppTrackingTransparency

let mixPanelProjectToken = "df948aa0c8dc30f5c784b9cb19c125cc"

class MixPanelManager {
  static let shared = MixPanelManager()
  
  func configClient() {
    Mixpanel.initialize(token: mixPanelProjectToken)
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
