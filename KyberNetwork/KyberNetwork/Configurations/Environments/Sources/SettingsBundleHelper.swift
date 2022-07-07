//
//  SettingsBundleHelper.swift
//  KyberNetwork
//
//  Created by Com1 on 04/07/2022.
//

import Foundation
class SettingsBundleHelper {
  struct SettingsBundleKeys {
    static let APIEndpointSetting = "apiEndpointSetting"
    static let useMainnet = "useMainnet"
    static let environmentSetting = "environmentSetting"
  }
  
  static func defaultEnvironment() -> KNEnvironment {
    if let value = UserDefaults.standard.string(forKey: SettingsBundleKeys.environmentSetting) {
      if value == "Production" {
        return .production
      } else if  value == "Staging" {
        return .staging
      } else {
        return . ropsten
      }
    }
    return .staging
  }
  
  static func defaultAPIEndpoint() -> KNEnvironment {
    if let value = UserDefaults.standard.string(forKey: SettingsBundleKeys.APIEndpointSetting) {
      if value == "Production" {
        return .production
      } else if  value == "Staging" {
        return .staging
      } else {
        return . ropsten
      }
    }
    return .staging
  }
}
