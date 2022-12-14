//
//  GasPrice.swift
//  Services
//
//  Created by Tung Nguyen on 01/11/2022.
//

import Foundation

public struct GasPriceResponse: Codable {
    public let timestamp: Int
    public let gasPrice: GasPrice
    public let priorityFee: GasPrice?
    public let baseFee: String?
    public let estTime: EstTime
}

public struct EstTime: Codable {
    public let fast, slow, standard: Int
}

public struct GasPrice: Codable {
    public let fast, standard, low, `default`: String
}
