//
//  KeyManager.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation
import KeychainSwift

class SecuredDataManager {
  
  let keychain: KeychainSwift = KeychainSwift(keyPrefix: "KRYSTAL_WALLET_MANAGER")
  let defaultKeychainAccess: KeychainSwiftAccessOptions = .accessibleWhenUnlockedThisDeviceOnly
  
  func save(key: String, value: String) {
    keychain.set(value, forKey: key, withAccess: defaultKeychainAccess)
  }
  
  func getValue(key: String) -> String? {
    return keychain.get(key)
  }
  
}
