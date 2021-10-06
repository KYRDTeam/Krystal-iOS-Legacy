//
//  LiquidityPoolModel.swift
//  KyberNetwork
//
//  Created by Com1 on 05/10/2021.
//

import UIKit

class LiquidityPoolModel: Codable {
  var poolAdress: String
  var poolSymbol: String
  var poolName: String
  /// pair token of current pool
  var lpTokenArray: [LPTokenModel]
  
  init(poolJSON: JSONDictionary, tokensJSON: [JSONDictionary]) {
    self.poolAdress = poolJSON["address"] as? String ?? ""
    self.poolSymbol = poolJSON["symbol"] as? String ?? ""
    self.poolName = poolJSON["name"] as? String ?? ""
    
    var tokenArray: [LPTokenModel] = []
    for jsonItem in tokensJSON {
      if let tokenJson = jsonItem["token"] as? JSONDictionary, let quotesJson = jsonItem["quotes"] as? JSONDictionary {
        let lpTokenModel = LPTokenModel(tokenJson: tokenJson, quotesJson: quotesJson, json: jsonItem)
        tokenArray.append(lpTokenModel)
      }
    }
    self.lpTokenArray = tokenArray
  }
}
