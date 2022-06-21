//
//  WalletType.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import WalletCore

public enum KAddressType: Int {
  case evm = 0
  case solana
  
  var coinType: CoinType {
    switch self {
    case .evm:
      return .ethereum
    case .solana:
      return .solana
    }
  }
}
