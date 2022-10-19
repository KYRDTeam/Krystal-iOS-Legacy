//
//  TokenPrice.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation

public struct TokenPrice: Codable {
    public let address: String
    public var usd: Double
    public var usdMarketCap: Double
    public var usd24hVol: Double
    public var usd24hChange: Double
    public var btc: Double
    public var btcMarketCap: Double
    public var btc24hVol: Double
    public var btc24hChange: Double
    public var eth: Double
    public var ethMarketCap: Double
    public var eth24hVol: Double
    public var eth24hChange: Double
//    public var quote: Double
//    public var quoteMarketCap: Double
//    public var quote24hVol: Double
//    public var quote24hChange: Double
    
    public init(address: String, quotes: [String: Quote]) {
        self.address = address
        self.usd = quotes["usd"]?.price ?? 0.0
        self.usdMarketCap = quotes["usd"]?.marketCap ?? 0.0
        self.usd24hVol = quotes["usd"]?.volume24H ?? 0.0
        self.usd24hChange = quotes["usd"]?.price24HChangePercentage ?? 0.0
        self.btc = quotes["btc"]?.price ?? 0.0
        self.btcMarketCap = quotes["btc"]?.marketCap ?? 0.0
        self.btc24hVol = quotes["btc"]?.volume24H ?? 0.0
        self.btc24hChange = quotes["btc"]?.price24HChangePercentage ?? 0.0
        self.eth = quotes["eth"]?.price ?? 0.0
        self.ethMarketCap = quotes["eth"]?.marketCap ?? 0.0
        self.eth24hVol = quotes["eth"]?.volume24H ?? 0.0
        self.eth24hChange = quotes["eth"]?.price24HChangePercentage ?? 0.0
//
//        let quote = KNGeneralProvider.shared.currentChain.quoteToken().lowercased()
//        self.quote = quotes[quote]?.price ?? 0.0
//        self.quoteMarketCap = quotes[quote]?.marketCap ?? 0.0
//        self.quote24hVol = quotes[quote]?.volume24H ?? 0.0
//        self.quote24hChange = quotes[quote]?.price24HChangePercentage ?? 0.0
    }
    
}

public struct Quote: Codable {
    public let symbol: String
    public let price, marketCap, volume24H, price24HChange: Double
    public let price24HChangePercentage: Double
    
    enum CodingKeys: String, CodingKey {
        case symbol, price, marketCap
        case volume24H = "volume24h"
        case price24HChange = "price24hChange"
        case price24HChangePercentage = "price24hChangePercentage"
    }
}
