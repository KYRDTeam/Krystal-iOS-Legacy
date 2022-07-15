//
//  TokenDTO.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/07/2022.
//

import Foundation

struct TokenDTO: Decodable {
  var address: String
  var symbol: String
  var name: String
  var decimals: Int
  var logo: String
  var tag: String
  var usd: Double
  var usdMarketCap: Double
  var usd24hVol: Double
  var usd24hChange: Double
  var usd24hChangePercentage: Double
  var quotes: [String: TokenQuoteDTO]
}
