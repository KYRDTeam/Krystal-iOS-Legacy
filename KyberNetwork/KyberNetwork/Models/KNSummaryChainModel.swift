//
//  KNSummaryChainModel.swift
//  KyberNetwork
//
//  Created by Com1 on 04/11/2021.
//

import UIKit

class KNSummaryChainModel: Codable {
  var chainName: String
  var usdValue: Double
  var percentage: Double
  var quotes: [String: UnitValueModel]
  
  init(json: JSONDictionary) {
    self.chainName = json["chainName"] as? String ?? ""
    self.usdValue = json["usdValue"] as? Double ?? 0.0
    self.percentage = json["percentage"] as? Double ?? 0.0

    var quoteArray: [String: UnitValueModel] = [:]
    if let quotesJson = json["quotes"] as? JSONDictionary {
      var unitValueModel: UnitValueModel
      if let avaxJson = quotesJson["avax"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: avaxJson)
        quoteArray["avax"] = unitValueModel
      }

      if let bnbJson = quotesJson["bnb"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: bnbJson)
        quoteArray["bnb"] = unitValueModel
      }

      if let btcJson = quotesJson["btc"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: btcJson)
        quoteArray["btc"] = unitValueModel
      }

      if let ethJson = quotesJson["eth"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: ethJson)
        quoteArray["eth"] = unitValueModel
      }

      if let maticJson = quotesJson["matic"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: maticJson)
        quoteArray["matic"] = unitValueModel
      }
      
      if let usdJson = quotesJson["usd"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: usdJson)
        quoteArray["usd"] = unitValueModel
      }
    }
    self.quotes = quoteArray
  }

  func chainType() -> ChainType {
    if chainName == "bsc" {
      return .bsc
    } else if chainName == "ethereum" {
      return .eth
    } else if chainName == "polygon" {
      return .polygon
    } else {
      return .avalanche
    }
  }
}
