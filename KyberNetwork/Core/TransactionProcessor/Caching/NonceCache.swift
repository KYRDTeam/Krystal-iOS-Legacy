//
//  NonceCache.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 13/06/2022.
//

import Foundation
import KrystalWallets

class NonceCache {
  
  private init() {}
  
  static let shared = NonceCache()
  
  var chainNonces: [ChainType: [String: Int]] = [:]
  
  func increaseNonce(address: String, chain: ChainType, increment: Int = 1) {
    if let chainDict = chainNonces[chain] {
      let currentNonce = chainDict[address] ?? 0
      chainNonces[chain]?[address] = currentNonce + 1
    } else {
      chainNonces[chain] = [address: 1]
    }
  }
  
  func updateNonce(address: String, chain: ChainType, nonce: Int) {
    var chainDict = chainNonces[chain] ?? [:]
    chainDict[address] = nonce
    chainNonces[chain] = chainDict
  }
  
  func getCachingNonce(address: String, chain: ChainType) -> Int {
    return chainNonces[chain]?[address] ?? 0
  }
  
  func resetNonce(wallet: KWallet) {
    ChainType.allCases.forEach { chain in
      let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id, addressType: chain.addressType)
      addresses.forEach { address in
        chainNonces[chain]?[address.addressString] = 0
      }
    }
  }
  
}
