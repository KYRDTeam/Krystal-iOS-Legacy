//
//  SettingsBundleHelper.swift
//  KyberNetwork
//
//  Created by Com1 on 04/07/2022.
//

import Foundation
class SettingsBundleHelper {
  struct SettingsBundleKeys {
    static let environmentSetting = "environmentSetting"
  }
  
  static func defaultEnvironment() -> KNEnvironment {
    if let value = UserDefaults.standard.string(forKey: SettingsBundleKeys.environmentSetting) {
      if value == "Production" {
        return .production
      } else {
        return .ropsten
      }
    }
    return .ropsten
  }
}
