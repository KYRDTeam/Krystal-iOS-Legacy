//
//  WalletManagerFactory.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 04/05/2022.
//

import Foundation

class WalletManagerFactory {
  
  func create(chain: ChainType) -> WalletManager {
    switch chain {
    case .solana:
      return SolanaWalletManager()
    default:
      return EVMWalletManager()
    }
  }
  
}
