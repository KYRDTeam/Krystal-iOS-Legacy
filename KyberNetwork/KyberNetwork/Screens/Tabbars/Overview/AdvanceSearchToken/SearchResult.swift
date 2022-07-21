//
//  SearchResult.swift
//  KyberNetwork
//
//  Created by Com1 on 21/06/2022.
//

import UIKit

class SearchResult: Codable {
  var tokens: [ResultToken]
  var portfolios: [Portfolio]
  init(json: JSONDictionary) {
    var tokensArray: [ResultToken] = []
    var portfolioArray: [Portfolio] = []
    if let tokens = json["tokens"] as? [JSONDictionary] {
      tokens.forEach { tokenJson in
        tokensArray.append(ResultToken(json: tokenJson))
      }
    }
    if let portfolios = json["portfolios"] as? [JSONDictionary] {
      portfolios.forEach { portfolioJson in
        let portfolio = Portfolio(json: portfolioJson)
        if !portfolio.id.isEmpty {
          portfolioArray.append(portfolio)
        }
      }
    }
    self.tokens = tokensArray
    self.portfolios = portfolioArray
  }
}
