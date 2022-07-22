//
//  WalletUtilities.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/06/2022.
//

import Foundation
import KrystalWallets

class WalletUtilities {
  
  static func isAddressValid(address: String, chainType: ChainType) -> Bool {
    return WalletManager.shared.validateAddress(address: address, forAddressType: chainType.addressType)
  }
  
}
