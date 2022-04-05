//
//  MixPanelManager.swift
//  KyberNetwork
//
//  Created by Com1 on 05/04/2022.
//
import Mixpanel
import Foundation

let mixPanelProjectToken = "df948aa0c8dc30f5c784b9cb19c125cc"

class MixPanelManager {
  static let shared = MixPanelManager()
  
  func configClient() {
    Mixpanel.initialize(token: mixPanelProjectToken)
  }
  
  func updateWalletAddress(address: String) {
    Mixpanel.mainInstance().track(event: "wallet_address", properties: [
      "user-id": address
    ])
  }
}
