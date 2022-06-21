//
//  WalletCache.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/06/2022.
//

import Foundation
import KrystalWallets

class WalletCache {
  
  private init() {}
  
  static let shared = WalletCache()
  let userDefaults = UserDefaults.standard
  let decoder = JSONDecoder()
  let encoder = JSONEncoder()
  
  let kLastUsedWallet = "LAST_USED_WALLET"
  let kIsWalletBackedUp = "IS_BACKED_UP_"
  
  var lastUsedAddress: KAddress? {
    set {
      guard let data = try? encoder.encode(newValue) else {
        return
      }
      userDefaults.set(data, forKey: kLastUsedWallet)
    }
    get {
      guard let data = userDefaults.data(forKey: kLastUsedWallet) else {
        return nil
      }
      return try? decoder.decode(KAddress.self, from: data)
    }
  }
  
  func isWalletBackedUp(walletID: String) -> Bool {
    return userDefaults.bool(forKey: kIsWalletBackedUp + walletID)
  }
  
  func markWalletBackedUp(walletID: String) {
    userDefaults.set(true, forKey: kIsWalletBackedUp + walletID)
  }
  
  func unmarkWalletBackedUp(walletID: String) {
    userDefaults.removeObject(forKey: kIsWalletBackedUp + walletID)
  }
  
}
