//
//  TradingViewData.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/06/2022.
//

import Foundation

// MARK: - TradingViewChartResponse
struct TradingViewChartResponse: Codable {
    let timestamp: Int
    let data: [TradingViewData]
}

// MARK: - Datum
struct TradingViewData: Codable {
    let openTime: Int
    let datumOpen, close, high, low: Double
    let volume: Double

    enum CodingKeys: String, CodingKey {
        case openTime
        case datumOpen = "open"
        case close, high, low, volume
    }
}
