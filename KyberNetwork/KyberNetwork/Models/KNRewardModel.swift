//
//  KNRewardModel.swift
//  KyberNetwork
//
//  Created by Com1 on 13/10/2021.
//
import BigInt

class KNRewardModel: Codable {
  let rewardName: String
  let rewardSymbol: String
  let rewardImage: String
  let amount: Double
  let symbol: String
  let value: Double
  let source: String
  let status: String
  let timestamp: Int
  
  init(json: JSONDictionary) {
    self.rewardName = json["rewardName"] as? String ?? ""
    self.rewardSymbol = json["rewardSymbol"] as? String ?? ""
    self.rewardImage = json["rewardImage"] as? String ?? ""
    self.source = json["source"] as? String ?? ""
    self.status = json["status"] as? String ?? ""
    self.timestamp = json["timestamp"] as? Int ?? 0
    self.amount = json["amount"] as? Double ?? 0.0
    if let quote = json["quote"] as? JSONDictionary {
      self.symbol = quote["symbol"] as? String ?? ""
      self.value = quote["value"] as? Double ?? 0.0
    } else {
      self.symbol = ""
      self.value = 0.0
    }
  }
}
