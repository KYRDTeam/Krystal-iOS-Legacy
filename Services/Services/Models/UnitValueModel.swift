//
//  UnitValueModel.swift
//  Services
//
//  Created by Com1 on 01/12/2022.
//

import UIKit
import BigInt
import Utilities

public class UnitValueModel: Codable {
  public var symbol: String
  public var value: Double
  public var rate: Double
  public var price: Double = 0
  
  public init(symbol: String, value: Double, rate: Double) {
    self.symbol = symbol
    self.value = value
    self.rate = rate
  }
  
  public init(json: JSONDictionary) {
    self.symbol = json["symbol"] as? String ?? ""
    self.value = json["value"] as? Double ?? 0.0
    self.rate = json["rate"] as? Double ?? 0.0
    self.price = json["price"] as? Double ?? 0.0
  }
}
