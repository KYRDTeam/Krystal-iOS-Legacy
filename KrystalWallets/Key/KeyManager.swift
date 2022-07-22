//
//  KeyManager.swift
//  KrystalWallets
//
//  Created by Tung Nguyen on 17/06/2022.
//

import Foundation
import KeychainSwift

class KeyManager {
  
  private let keychain: KeychainSwift
  private let defaultKeychainAccess: KeychainSwiftAccessOptions = .accessibleWhenUnlockedThisDeviceOnly
  let keychainKeyPrefix = "krystal.wallets.keys"
  
  init() {
    self.keychain = KeychainSwift(keyPrefix: keychainKeyPrefix)
    self.keychain.synchronizable = false
  }
  
  func value(forKey key: String) -> String? {
    return keychain.get(key)
  }
  
  func save(value: String, forKey key: String) {
    keychain.set(value, forKey: key, withAccess: defaultKeychainAccess)
  }
  
  func removeValue(forKey key: String) {
    keychain.delete(key)
  }
  
}
