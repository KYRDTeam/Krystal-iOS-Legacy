//
//  TokenDetail.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation

public struct TokenDetailResponse: Codable {
    public let timestamp: Int
    public let result: TokenDetailInfo?
}

public struct TokenDetailInfo: Codable {
    public let address, symbol, name: String
    public let decimals: Int
    public let logo, resultDescription: String
    public let links: Links
    public let markets: [String: Market]
    public let tag: String
    
    enum CodingKeys: String, CodingKey {
        case address, symbol, name, decimals, logo
        case resultDescription = "description"
        case links, markets
        case tag
    }
}

public struct Links: Codable {
    public let homepage: String
    public let twitterScreenName: String
    public let discord: String
    public let telegram: String
    public let twitter: String
}

public struct Market: Codable {
    public let symbol: String
    public let price, priceChange24H, priceChange1HPercentage, priceChange24HPercentage: Double
    public let priceChange7DPercentage, priceChange30DPercentage, priceChange200DPercentage, priceChange1YPercentage: Double
    public let marketCap, marketCapChange24H, marketCapChange24HPercentage, volume24H: Double
    public let high24H, low24H, ath, athChangePercentage: Double
    public let athDate: Int
    public let atl, atlChangePercentage: Double
    public let atlDate: Int
    
    enum CodingKeys: String, CodingKey {
        case symbol, price
        case priceChange24H = "priceChange24h"
        case priceChange1HPercentage = "priceChange1hPercentage"
        case priceChange24HPercentage = "priceChange24hPercentage"
        case priceChange7DPercentage = "priceChange7dPercentage"
        case priceChange30DPercentage = "priceChange30dPercentage"
        case priceChange200DPercentage = "priceChange200dPercentage"
        case priceChange1YPercentage = "priceChange1yPercentage"
        case marketCap
        case marketCapChange24H = "marketCapChange24h"
        case marketCapChange24HPercentage = "marketCapChange24hPercentage"
        case volume24H = "volume24h"
        case high24H = "high24h"
        case low24H = "low24h"
        case ath, athChangePercentage, athDate, atl, atlChangePercentage, atlDate
    }
}
