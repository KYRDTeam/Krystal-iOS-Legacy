//
//  AppFeatureFlag.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation
import Dependencies

class AppFeatureFlag: FeatureFlag {
  
  func isFeatureEnabled(key: String) -> Bool {
    return FeatureFlagManager.shared.showFeature(forKey: key)
  }
  
}
