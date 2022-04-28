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

      if let btcJson = quotesJson["btc"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: btcJson)
        quoteArray["btc"] = unitValueModel
      }

      if let ethJson = quotesJson["eth"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: ethJson)
        quoteArray["eth"] = unitValueModel
      }
      
      if let usdJson = quotesJson["usd"] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: usdJson)
        quoteArray["usd"] = unitValueModel
      }
      let quote = KNGeneralProvider.shared.currentChain.quoteToken().lowercased()
      if let ftmJson = quotesJson[quote] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: ftmJson)
        quoteArray[quote] = unitValueModel
      }
    }
    self.quotes = quoteArray
  }

  func chainType() -> ChainType {
    return ChainType.make(chainID: chainId) ?? .eth
  }
  
  static func defaultValue(chainId: Int) -> KNSummaryChainModel {
    return KNSummaryChainModel(chainId: chainId, usdValue: 0, percentage: 0, quotes: [:])
  }
}
