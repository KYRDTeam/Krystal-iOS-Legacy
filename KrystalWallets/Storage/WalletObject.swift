//
//  Wallet.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation
import RealmSwift

class WalletObject: Object {
  @objc dynamic var id: String = ""
  @objc dynamic var importType: Int = -1
  @objc dynamic var name: String = ""
  
  convenience init(id: String, importType: KImportType, name: String) {
    self.init()
    self.id = id
    self.importType = importType.rawValue
    self.name = name
  }
  
  override class func primaryKey() -> String? {
    return "id"
  }
  
  func toWallet() -> KWallet {
    return .init(id: id, importType: KImportType(rawValue: importType) ?? .mnemonic, name: name)
  }
}
