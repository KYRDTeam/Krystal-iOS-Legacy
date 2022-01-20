//
//  KNSummaryChainModel.swift
//  KyberNetwork
//
//  Created by Com1 on 04/11/2021.
//

import UIKit

class KNSummaryChainModel: Codable {
  var chainId: Int
  var usdValue: Double
  var percentage: Double
  var quotes: [String: UnitValueModel]
  
  init(chainId: Int, usdValue: Double, percentage: Double, quotes:[String: UnitValueModel]) {
    self.chainId = chainId
    self.usdValue = usdValue
    self.percentage = percentage
    self.quotes = quotes
  }
  
  init(json: JSONDictionary) {
    self.chainId = json["chainID"] as? Int ?? 0
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
    switch chainId {
    case Constants.ethMainnetPRC.chainID, Constants.ethRoptenPRC.chainID:
      return .eth
    case Constants.bscMainnetPRC.chainID, Constants.bscRoptenPRC.chainID:
      return .bsc
    case Constants.polygonMainnetPRC.chainID, Constants.polygonRoptenPRC.chainID:
      return .polygon
    case Constants.avalancheMainnetPRC.chainID, Constants.avalancheRoptenPRC.chainID:
      return .avalanche
    case Constants.fantomMainnetRPC.chainID:
      return .fantom
    default:
      return .avalanche
    }
  }
  
  static func defaultValue(chainId: Int) -> KNSummaryChainModel {
    return KNSummaryChainModel(chainId: chainId, usdValue: 0, percentage: 0, quotes: [:])
  }
}
