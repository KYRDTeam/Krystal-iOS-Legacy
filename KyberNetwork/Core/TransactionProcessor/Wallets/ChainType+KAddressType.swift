//
//  ChainType+KAddressType.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 12/06/2022.
//

import Foundation
import KrystalWallets

extension ChainType {
  
  var addressType: KAddressType {
    switch self {
    case .solana:
      return .solana
    default:
      return .evm
    }
  }
  
  var canExportKeystore: Bool {
    switch self {
    case .solana:
      return false
    default:
      return true
    }
  }
  
}

extension KAddressType {
  
  var importChainType: ImportWalletChainType {
    switch self {
    case .evm:
      return .evm
    case .solana:
      return .solana
    }
  }
  
}
