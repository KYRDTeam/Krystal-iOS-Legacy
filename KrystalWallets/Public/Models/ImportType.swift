//
//  ImportType.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation

public enum KImportType: Int {
  case mnemonic = 0
  case privateKey
  
  public init(value: Int) {
    self = KImportType(rawValue: value) ?? .mnemonic
  }
}
