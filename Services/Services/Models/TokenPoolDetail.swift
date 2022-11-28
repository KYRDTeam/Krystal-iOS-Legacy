//
//  TokenPoolDetail.swift
//  Services
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation
import Utilities

public class TokenPoolDetail: Codable {
  public var address: String
  public var tvl: Double
  public var chainId: Int
  public var name: String
  public var token0: PoolPairToken
  public var token1: PoolPairToken
  
  init(json: JSONDictionary) {
    self.address = json["address"] as? String ?? ""
    self.tvl = json["tvl"] as? Double ?? 0.0
    self.chainId = json["chainId"] as? Int ?? 0
    self.name = json["name"] as? String ?? ""
    self.token0 = PoolPairToken(json: json["token0"] as? JSONDictionary ?? JSONDictionary())
    self.token1 = PoolPairToken(json: json["token1"] as? JSONDictionary ?? JSONDictionary())
  }
}

public class PoolPairToken: Codable {
  public var address: String
  public var name: String
  public var symbol: String
  public var logo: String
  public var tvl: Double
  public var decimals: Int
  public var usdValue: Double

  init(json: JSONDictionary) {
    self.address = json["id"] as? String ?? ""
    self.name = json["name"] as? String ?? ""
    self.symbol = json["symbol"] as? String ?? ""
    self.decimals = json["decimals"] as? Int ?? 0
    self.logo = json["logo"] as? String ?? ""
    self.tvl = json["tvl"] as? Double ?? 0.0
    self.usdValue = json["usdValue"] as? Double ?? 0.0
  }
}
