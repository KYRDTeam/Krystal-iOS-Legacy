// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import Foundation
import Utilities

struct Balance: BalanceProtocol {

    let value: BigInt

    init(value: BigInt) {
        self.value = value
    }

    var isZero: Bool {
        return value.isZero
    }

    var amountShort: String {
        return EtherNumberFormatter.short.string(from: value)
    }

    var amountFull: String {
        return EtherNumberFormatter.full.string(from: value)
    }
}

struct BalancesResponse: Codable {
    let timestamp: Int
    let balances: [BalanceData]
}

struct BalanceData: Codable {
    let token: Token
    let balance: String
//    let quote, quoteRate: Double
}

class Quotes: Codable {
  let symbol: String
  let price: Double
  let value: Double
  let priceChange24hPercentage: Double

  init(json: JSONDictionary) {
    self.symbol = json["symbol"] as? String ?? ""
    self.price = json["price"] as? Double ?? 0.0
    self.value = json["value"] as? Double ?? 0.0
    self.priceChange24hPercentage = json["priceChange24hPercentage"] as? Double ?? 0.0
  }
}

class BalanceModel: Codable {
  let token: Token
  let balance: String
  let userAddress: String
  let quotes: [String: Quotes]
  
  init(json: JSONDictionary) {
    if let tokenJson = json["token"] as? JSONDictionary {
      self.token = Token(dictionary: tokenJson)
    } else {
      self.token = Token(name: "", symbol: "", address: "", decimals: 0, logo: "")
    }
    self.balance = json["balance"] as? String ?? ""
    self.userAddress = json["userAddress"] as? String ?? ""
    var quotesValue: [String: Quotes] = [:]
    
    if let quotesJson = json["quotes"] as? JSONDictionary {
      quotesJson.keys.forEach { key in
        if let quoteJson = quotesJson[key] as? JSONDictionary {
          let quote = Quotes(json: quoteJson)
          quotesValue[key] = quote
        }
      }
    }
    self.quotes = quotesValue
  }
}

class ChainBalanceModel: Codable {
  let chainName: String
  let chainId: Int
  let chainLogo: String
  let balances: [BalanceModel]
  
  init(json: JSONDictionary) {
    self.chainName = json["chainName"] as? String ?? ""
    self.chainId = json["chainId"] as? Int ?? 0
    self.chainLogo = json["chainLogo"] as? String ?? ""
    var balanceModels: [BalanceModel] = []
    if let balances = json["balances"] as? [JSONDictionary] {
      balances.forEach { balanceJson in
        let balance = BalanceModel(json: balanceJson)
        balanceModels.append(balance)
      }
    }
    self.balances = balanceModels
  }
}
