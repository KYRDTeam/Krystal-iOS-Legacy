//
//  EVMWalletManager.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 04/05/2022.
//

import Foundation
import WalletCore

class EVMWalletManager: WalletManager {
  
  func isAddressValid(_ address: String) -> Bool {
    return Address(string: string) != nil
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
  
  func exportPrivateKey(wallet: Wallet) -> Result<Data, KeystoreError> {
    <#code#>
  }
  
  func exportKeyPair(privateKey: PrivateKey) -> String {
    <#code#>
  }
  
  func importKeyPair(_ key: String) -> (String?, Account?, String?) {
    <#code#>
  }
  
  
  
  
}
