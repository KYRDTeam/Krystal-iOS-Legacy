//
//  GasPrice.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 14/10/2021.
//

import Foundation

// MARK: - GasPriceResponse
struct GasPriceResponse: Codable {
  let timestamp: Int
  let gasPrice: GasPrice
  let priorityFee: GasPrice?
  let baseFee: String?
  let estTime: EstTime
}

// MARK: - EstTime
struct EstTime: Codable {
    let fast, slow, standard: Int
}

// MARK: - GasPrice
struct GasPrice: Codable {
  let fast, standard, low, gasPriceDefault: String
  
  enum CodingKeys: String, CodingKey {
    case fast, standard, low
    case gasPriceDefault = "default"
  }
}
