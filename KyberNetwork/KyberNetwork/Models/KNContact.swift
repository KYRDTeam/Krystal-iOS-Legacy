// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import TrustCore

class KNContact: Object {

  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var lastUsed: Date = Date()
  @objc dynamic var chainType: Int = 0

  convenience init(address: String, name: String, chainType: Int) {
    self.init()
    self.name = name
    self.address = address
    self.chainType = chainType
    self.lastUsed = Date()
  }

  override static func primaryKey() -> String {
    return "address"
  }
  
  func clone() -> KNContact {
    return KNContact(address: self.address, name: self.name, chainType: self.chainType)
  }
  
  func getImportType() -> ImportWalletChainType {
    return ImportWalletChainType(rawValue: self.chainType) ?? .evm
  }
}
