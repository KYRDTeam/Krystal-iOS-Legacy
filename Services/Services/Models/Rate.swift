//
//  PlatformRate.swift
//  Services
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import BigInt

struct RateResponse: Codable {
    let timestamp: Int
    let rates: [Rate]
}

public struct Rate: Codable {
  public var rate: String
  public let platform, platformShort: String
  public let platformIcon: String
  public let hint: String
  public let amount: String
  public let tradePath: [String]?
  public var estimatedGas: Int
  public let estGasConsumed: Int?
  public var priceImpact: Int
  public var l1Fee: BigInt?
}
