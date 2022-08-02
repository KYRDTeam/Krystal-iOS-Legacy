//
//  PlatformRate.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation

struct PlatformRate: Decodable {
  let rate, platform, platformShort: String
  let platformIcon: String
  let hint: String
  var estimatedGas: Int
}
