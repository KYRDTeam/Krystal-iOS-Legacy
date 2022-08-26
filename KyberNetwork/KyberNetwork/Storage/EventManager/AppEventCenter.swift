//
//  AppEventCenter.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 03/06/2022.
//

import Foundation
import KrystalWallets

class AppEventCenter {
  
  private init() {}
  
  static let shared = AppEventCenter()
  let notificationCenter = NotificationCenter.default
  
  let kAppDidChangeAddress = Notification.Name("kAppDidChangeAddress")
  let kAppDidChangeCurrentAddressData = Notification.Name("kAppDidChangeCurrentAddressData")
  let kAppDidSwitchChain = Notification.Name("kChangeChainNotificationKey")
  let kWalletListHasUpdate = Notification.Name("kWalletListHasUpdateKey")
  
  func switchAddress(address: KAddress) {
    notificationCenter.post(
      Notification(name: kAppDidChangeAddress, object: nil, userInfo: ["address": address])
    )
  }
  
  func switchChain(chain: ChainType) {
    notificationCenter.post(
      Notification(name: kAppDidSwitchChain, object: nil, userInfo: ["chain": chain])
    )
  }
  
  func walletListHasUpdate() {
    notificationCenter.post(Notification(name: kWalletListHasUpdate))
  }
  
  func currentAddressUpdated() {
    notificationCenter.post(
      Notification(name: kAppDidChangeCurrentAddressData)
    )
  }
  
}
