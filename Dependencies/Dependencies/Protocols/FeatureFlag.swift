//
//  FeatureFlag.swift
//  Dependencies
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation

public protocol FeatureFlag {
  func isFeatureEnabled(key: String) -> Bool
}
