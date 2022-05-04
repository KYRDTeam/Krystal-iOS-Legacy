//
//  SolanaWalletManager.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 04/05/2022.
//

import Foundation
import WalletCore
import KeychainSwift

class SolanaWalletManager {
  var wallets: [Wallet] = []
  let keyStore: KeyStore
  let keychain: KeychainSwift
  let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
  
  init() {
    let keyDirURL = URL(fileURLWithPath: datadir + "/solanaKeyStore")
    self.keyStore = try! KeyStore(keyDirectory: keyDirURL)
    self.keychain = KeychainSwift(keyPrefix: Constants.keychainKeyPrefix)
  }
  
  private func exportKeyPair(walletID: String) -> PrivateKey? {
    let filtered = self.keyStore.wallets.first { element in
      return element.identifier == walletID
    }
    
    guard let wallet = filtered, let password = self.getPassword(for: wallet), let data = try? self.keyStore.exportPrivateKey(wallet: wallet, password: password) else { return nil }
    
    let pk = PrivateKey(data: data)
    return pk
  }
  
  private func getPassword(for account: WalletCore.Wallet) -> String? {
    let key = keychainKey(for: account)
    return keychain.get(key)
  }
  
  internal func keychainKey(for account: WalletCore.Wallet) -> String {
      return account.identifier
  }
}

extension SolanaWalletManager: WalletManager {
  
  func isAddressValid(_ address: String) -> Bool {
    return AnyAddress.isValid(string: address, coin: .solana)
  }
  
  func addWatchWallet(name: String, address: String) {
    <#code#>
  }
  
  func removeWatchWallet(address: String) {
    <#code#>
  }
  
  func removeWallet(walletID: String) {
    <#code#>
  }
  
  func getWalletAddress(fromSeeds seeds: String) -> String {
    <#code#>
  }
  
  func importPrivateKey(privateKey: String, completion: (Result<Wallet, KeystoreError>) -> ()) {
    <#code#>
  }
  
  func exportPrivateKey(keyPair: String) -> PrivateKey? {
    <#code#>
  }
  
  func exportPrivateKey(wallet: Wallet) -> Result<String, KeystoreError> {
    <#code#>
  }
  
  func exportKeyPair(privateKey: PrivateKey) -> String {
    <#code#>
  }
  
  func importKeyPair(_ key: String) -> (String?, Account?, String?) {
    <#code#>
  }
  
}
