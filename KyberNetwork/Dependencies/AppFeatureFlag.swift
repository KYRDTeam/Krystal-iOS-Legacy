//
//  AppFeatureFlag.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation
import Dependencies

class AppFeatureFlag: FeatureFlag {
  
    func isFeatureEnabled(key: String, defaultValue: Bool) -> Bool {
        return FeatureFlagManager.shared.showFeature(forKey: key, defaultValue: defaultValue)
    }
  
}
