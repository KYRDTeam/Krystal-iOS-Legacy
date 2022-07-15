//
//  KTokenQuote.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/07/2022.
//

import Foundation
import RealmSwift
import Realm

class KTokenQuoteObject: Object {
  @objc dynamic var symbol: String = ""
  @objc dynamic var price: Double = 0.0
  @objc dynamic var marketCap: Double = 0.0
  @objc dynamic var volume24h: Double = 0.0
  @objc dynamic var price24hChange: Double = 0.0
  @objc dynamic var price24hChangePercentage: Double = 0.0
  
  let token = LinkingObjects(fromType: KTokenObject.self, property: "quotes")
  
  init(dto: TokenQuoteDTO) {
    self.symbol = dto.symbol
    self.price = dto.price
    self.marketCap = dto.marketCap
    self.volume24h = dto.volume24h
    self.price24hChange = dto.price24hChange
    self.price24hChangePercentage = dto.price24hChangePercentage
  }
  
  override required init() {
    super.init()
  }
  
}
