//
//  UserDefault.swift
//  AppState
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation

@propertyWrapper
public struct AppStateUserDefault<Value> {
  let key: String
  let defaultValue: Value
  var container: UserDefaults = .standard
  
  public var wrappedValue: Value {
    get {
      return container.object(forKey: key) as? Value ?? defaultValue
    }
    set {
      container.set(newValue, forKey: key)
    }
  }
}
