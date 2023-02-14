//
//  Wallet.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation

public struct KWallet {
  public var id: String
  public var importType: KImportType
  public var name: String
    
  public init(id: String, importType: KImportType, name: String) {
    self.id = id
    self.importType = importType
    self.name = name
  }
    
}
