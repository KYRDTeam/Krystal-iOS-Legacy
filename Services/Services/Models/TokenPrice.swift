//
//  TokenPrice.swift
//  Services
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation

struct Quote: Codable {
  let symbol: String
  let price, marketCap, volume24H, price24HChange: Double
  let price24HChangePercentage: Double
  
  enum CodingKeys: String, CodingKey {
    case symbol, price, marketCap
    case volume24H = "volume24h"
    case price24HChange = "price24hChange"
    case price24HChangePercentage = "price24hChangePercentage"
  }
}

class TokenPrice: Codable {
  let address: String
  var usd: Double
  var usdMarketCap: Double
  var usd24hVol: Double
  var usd24hChange: Double
  var btc: Double
  var btcMarketCap: Double
  var btc24hVol: Double
  var btc24hChange: Double
  var eth: Double
  var ethMarketCap: Double
  var eth24hVol: Double
  var eth24hChange: Double
//  var quote: Double
//  var quoteMarketCap: Double
//  var quote24hVol: Double
//  var quote24hChange: Double
//  
  init(address: String, quotes: [String: Quote]) {
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
    
//    let quote = KNGeneralProvider.shared.currentChain.quoteToken().lowercased()
//    self.quote = quotes[quote]?.price ?? 0.0
//    self.quoteMarketCap = quotes[quote]?.marketCap ?? 0.0
//    self.quote24hVol = quotes[quote]?.volume24H ?? 0.0
//    self.quote24hChange = quotes[quote]?.price24HChangePercentage ?? 0.0
  }
  
}
