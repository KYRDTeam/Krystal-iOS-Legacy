//
//  LiquidityPoolModel.swift
//  KyberNetwork
//
//  Created by Com1 on 05/10/2021.
//

import UIKit

class LiquidityPoolModel: Codable {
  var project: String = "Liquidity Pool"
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

class ChainLiquidityPoolModel: Codable {
  let chainName: String
  let chainId: Int
  let chainLogo: String
  let balances: [LiquidityPoolModel]
  
  init(json: JSONDictionary) {
    self.chainName = json["chainName"] as? String ?? ""
    self.chainId = json["chainId"] as? Int ?? 0
    self.chainLogo = json["chainLogo"] as? String ?? ""

    var balanceModels: [LiquidityPoolModel] = []
    if let balances = json["balances"] as? [JSONDictionary] {
      balances.forEach { balanceJson in
        if let poolJSON = balanceJson["token"] as? JSONDictionary, let tokensJSON = balanceJson["underlying"] as? [JSONDictionary], let project = balanceJson["project"] as? String {
          let lpmodel = LiquidityPoolModel(poolJSON: poolJSON, tokensJSON: tokensJSON)
          lpmodel.project = project
          balanceModels.append(lpmodel)
        }
      }
    }
    self.balances = balanceModels
  }
}
