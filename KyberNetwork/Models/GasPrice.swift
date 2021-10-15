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
    let gasPrice, priorityFee: GasPrice
    let baseFee: String
}

// MARK: - GasPrice
struct GasPrice: Codable {
    let fast, standard, low, gasPriceDefault: String

    enum CodingKeys: String, CodingKey {
        case fast, standard, low
        case gasPriceDefault = "default"
    }
}
