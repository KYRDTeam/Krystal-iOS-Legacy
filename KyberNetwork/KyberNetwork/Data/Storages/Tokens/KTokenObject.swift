//
//  KTokenObject.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/07/2022.
//

import Foundation
import RealmSwift
import Realm

class KTokenObject: Object {
  @objc dynamic var address: String = "" {
    didSet {
      compoundPrimaryKey = compoundKey()
    }
  }
  @objc dynamic var chainID: Int = 0 {
    didSet {
      compoundPrimaryKey = compoundKey()
    }
  }
  @objc dynamic var name: String = ""
  @objc dynamic var symbol: String = ""
  @objc dynamic var decimals: Int = 0
  @objc dynamic var logo: String = ""
  @objc dynamic var tag: String = ""
  @objc dynamic var usd: Double = 0.0
  @objc dynamic var usdMarketCap: Double = 0.0
  @objc dynamic var usd24hVol: Double = 0.0
  @objc dynamic var usd24hChange: Double = 0.0
  @objc dynamic var usd24hChangePercentage: Double = 0.0
  let quotes = List<KTokenQuoteObject>()

  @objc dynamic var compoundPrimaryKey: String = ""
  
  init(chainID: Int, dto: TokenDTO) {
    super.init()
    self.chainID                = chainID
    self.address                = dto.address
    self.name                   = dto.name
    self.symbol                 = dto.symbol
    self.decimals               = dto.decimals
    self.logo                   = dto.logo
    self.tag                    = dto.tag
    self.usd                    = dto.usd
    self.usdMarketCap           = dto.usdMarketCap
    self.usd24hVol              = dto.usd24hVol
    self.usd24hChange           = dto.usd24hChange
    self.usd24hChangePercentage = dto.usd24hChangePercentage
    
    let quotes = dto.quotes.keys.compactMap { key in
      return dto.quotes[key].map { KTokenQuoteObject(dto: $0) }
    }
    self.quotes.append(objectsIn: quotes)
  }
  
  override static func primaryKey() -> String? {
    return "compoundPrimaryKey"
  }
  
  private func compoundKey() -> String {
    return "\(chainID)-\(address)"
  }
  
  override required init() {
    super.init()
  }
}
