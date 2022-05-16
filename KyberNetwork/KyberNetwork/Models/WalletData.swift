//
//  Wallet.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 13/04/2022.
//

import Foundation

struct WalletData: Equatable {
  let address: String
  let name: String
  let icon: String
  let isBackedUp: Bool
  let isWatchWallet: Bool
  let date: Date
  let chainType: ImportWalletChainType
  let storageType: StorageType
  let evmAddress: String
  let solanaAddress: String
  let walletID: String
  
  static func == (lhs: WalletData, rhs: WalletData) -> Bool {
    return lhs.address == rhs.address
  }
}
