//
//  LPTokenModel.swift
//  KyberNetwork
//
//  Created by Com1 on 05/10/2021.
//

import UIKit
import BigInt

class UnitValueModel: Codable {
  var symbol: String
  var value: Double
  var rate: Double
  
  init(symbol: String, value: Double, rate: Double) {
    self.symbol = symbol
    self.value = value
    self.rate = rate
  }
  
  init(json: JSONDictionary) {
    self.symbol = json["symbol"] as? String ?? ""
    self.value = json["value"] as? Double ?? 0.0
    self.rate = json["rate"] as? Double ?? 0.0
  }
}

class LPTokenModel: Codable {
  var token: Token
  var balance: String
  var quote: [String : UnitValueModel]
  
  init(token: Token, balance: String, quote: [String : UnitValueModel]) {
    self.token = token
    self.balance = balance
    self.quote = quote
  }
  
  init(tokenJson: JSONDictionary, quotesJson: JSONDictionary, json: JSONDictionary) {
    self.token = Token(dictionary: tokenJson)
    self.balance = json["balance"] as? String ?? ""
    
    var quoteArray: [String : UnitValueModel] = [:]
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
    
    self.quote = quoteArray
  }


  func getBalanceBigInt() -> BigInt {
    return BigInt(self.balance) ?? BigInt(0)
  }
  
  func getTokenValue(_ currency: CurrencyMode) -> Double {
    if let unitValueModel = quote[currency.toString()] {
      return unitValueModel.value
    }
    return 0.0
  }
}
