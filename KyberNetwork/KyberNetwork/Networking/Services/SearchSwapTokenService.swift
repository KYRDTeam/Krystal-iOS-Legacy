//
//  SearchSwapTokenService.swift
//  KyberNetwork
//
//  Created by Com1 on 05/08/2022.
//

import UIKit
import Moya

class SwapToken: Codable {
  var token: Token
  var balance: String
  var quotes: [String: UnitValueModel]
  
  init(json: JSONDictionary) {
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
      let quote = KNGeneralProvider.shared.currentChain.quoteToken().lowercased()
      if let quoteJson = quotesJson[quote] as? JSONDictionary {
        unitValueModel = UnitValueModel(json: quoteJson)
        quoteArray[quote] = unitValueModel
      }
    }
    self.quotes = quoteArray
  }
  
  init (token: Token) {
    self.token = token
    self.balance = "0"
    self.quotes = [:]
  }

}

class SearchSwapTokenService: NSObject {
  var searchTokensProcess: Cancellable?

  func getCommonBaseTokens(completion: @escaping ([Token]?) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    provider.request(.getCommonBaseToken) { result in
      switch result {
      case .success(let response):
        if let json = try? response.mapJSON() as? JSONDictionary ?? [:], let tokenJsons = json["tokens"] as? [JSONDictionary] {
          var tokens: [Token] = []
          tokenJsons.forEach { tokenJson in
            tokens.append(Token(dictionary: tokenJson))
          }
          completion(tokens)
        } else {
          completion(nil)
        }
      case .failure:
        completion(nil)
      }
    }
  }
  
  func getSearchTokens(address: String, query: String, orderBy: String, completion: @escaping ([SwapToken]?) -> ()) {
    if let searchTokensProcess = self.searchTokensProcess {
      searchTokensProcess.cancel()
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    self.searchTokensProcess = provider.request(.getSearchToken(address: address, query: query, orderBy: orderBy)) { result in
      switch result {
      case .success(let response):
        if let json = try? response.mapJSON() as? JSONDictionary ?? [:], let balancesJsons = json["balances"] as? [JSONDictionary] {
          var tokens: [SwapToken] = []
          balancesJsons.forEach { balanceJsons in
            tokens.append(SwapToken(json: balanceJsons))
          }
          completion(tokens)
        } else {
          completion(nil)
        }
      case .failure:
        completion(nil)
      }
    }
  }
}
