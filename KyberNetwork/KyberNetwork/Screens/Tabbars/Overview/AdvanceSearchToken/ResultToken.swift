//
//  ResultToken.swift
//  KyberNetwork
//
//  Created by Com1 on 21/06/2022.
//

import UIKit

class ResultToken: Codable {
  var id: String
  var chainId: Int
  var chainName: String
  var chainLogo: String
  var name: String
  var symbol: String
  var decimals: Int
  var logo: String
  var tag: String
  var usdValue: Double
  var tvl: Double
  
  init(json: JSONDictionary) {
    self.id = json["id"] as? String ?? ""
    self.chainId = json["chainId"] as? Int ?? 0
    self.chainName = json["chainName"] as? String ?? ""
    self.chainLogo = json["chainLogo"] as? String ?? ""
    self.name = json["name"] as? String ?? ""
    self.symbol = json["symbol"] as? String ?? ""
    self.decimals = json["decimals"] as? Int ?? 0
    self.logo = json["logo"] as? String ?? ""
    self.tag = json["tag"] as? String ?? ""
    self.usdValue = json["usdValue"] as? Double ?? 0.0
    self.tvl = json["tvl"] as? Double ?? 0.0
  }
}

