//
//  AddressObject.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation
import RealmSwift

class AddressObject: Object {
  @objc dynamic var id: String = ""
  @objc dynamic var walletID: String = ""
  @objc dynamic var addressType: Int = 0
  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  
  convenience init(walletID: String = "", addressType: KAddressType, address: String, name: String) {
    self.init()
    self.id = UUID().uuidString
    self.walletID = walletID
    self.addressType = addressType.rawValue
    self.address = address
    self.name = name
  }
  
  override class func primaryKey() -> String? {
    return "id"
  }
  
  func toAddress() -> KAddress {
    return .init(id: id, walletID: walletID, addressType: KAddressType(rawValue: addressType) ?? .evm, name: name, addressString: address)
  }
}
