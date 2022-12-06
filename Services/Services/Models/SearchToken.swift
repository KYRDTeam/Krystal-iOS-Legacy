//
//  SearchToken.swift
//  Services
//
//  Created by Com1 on 01/12/2022.
//

import Utilities
import AppState

public class SearchToken: Codable {
    public var token: Token
    public var balance: String
    public var quotes: [String: UnitValueModel]
    
    public init(json: JSONDictionary) {
      self.token = Token(dictionary: json["token"] as? JSONDictionary ?? [:])
      self.balance = json["balance"] as? String ?? ""
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
        let quote = AppState.shared.currentChain.quoteToken().lowercased()
        if let quoteJson = quotesJson[quote] as? JSONDictionary {
          unitValueModel = UnitValueModel(json: quoteJson)
          quoteArray[quote] = unitValueModel
        }
      }
      self.quotes = quoteArray
    }
    
    public init (token: Token) {
      self.token = token
      self.balance = "0"
      self.quotes = [:]
    }
}
