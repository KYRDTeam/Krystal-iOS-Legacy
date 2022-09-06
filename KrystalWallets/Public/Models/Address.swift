//
//  Address.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation

public struct KAddress {
  public var id: String
  public var walletID: String
  public var addressType: KAddressType
  public var name: String
  public var addressString: String
  
  public var isWatchWallet: Bool {
    return walletID.isEmpty
  }
  
  public var isBrowsingWallet: Bool {
    return id.isEmpty
  }
}
