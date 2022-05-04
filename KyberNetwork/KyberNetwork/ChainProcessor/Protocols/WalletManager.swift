//
//  WalletManager.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 04/05/2022.
//

import Foundation
import WalletCore

protocol WalletManager {
  var wallets: [Wallet] { get }
  
  func isAddressValid(_ address: String) -> Bool
  func addWatchWallet(name: String, address: String)
  func removeWatchWallet(address: String)
  func removeWallet(walletID: String)
  func getWalletAddress(fromSeeds seeds: String) -> String
  func importPrivateKey(privateKey: String, completion: (Result<Wallet, KeystoreError>) -> ())
  func exportPrivateKey(keyPair: String) -> PrivateKey?
  func exportPrivateKey(wallet: Wallet) -> Result<String, KeystoreError>
  func exportKeyPair(privateKey: PrivateKey) -> String
  func importKeyPair(_ key: String) -> (String?, Account?, String?)
}
