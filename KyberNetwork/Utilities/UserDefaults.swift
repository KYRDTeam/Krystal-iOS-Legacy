//
//  UserDefaults.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/06/2022.
//

import Foundation

@propertyWrapper
struct UserDefault<Value> {
  let key: String
  let defaultValue: Value
  var container: UserDefaults = .standard
  
  var wrappedValue: Value {
    get {
      return container.object(forKey: key) as? Value ?? defaultValue
    }
    set {
      container.set(newValue, forKey: key)
    }
  }
}

extension UserDefaults {
  
  @UserDefault(key: "has_migrated_keystore_wallets", defaultValue: false)
  static var hasMigratedKeystoreWallet: Bool
  
}
