//
//  TokenQuoteDTO.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/07/2022.
//

import Foundation

struct TokenQuoteDTO: Decodable {
  var symbol: String
  var price: Double
  var marketCap: Double
  var volume24h: Double
  var price24hChange: Double
  var price24hChangePercentage: Double
}
