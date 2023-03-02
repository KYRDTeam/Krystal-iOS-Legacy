//
//  MigratingWalletOperation.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 17/08/2022.
//

import Foundation
import KrystalWallets
import TrustKeystore
import Result
import AppState

class MigratingWalletOperation: AsyncOperation {
  
  let wallet: Wallet
  let walletObject: KNWalletObject
  let keystore: Keystore
  let walletManager = WalletManager.shared
  var onComplete: (() -> ())?
  
  init(keystore: Keystore, wallet: Wallet, walletObject: KNWalletObject) {
    self.keystore = keystore
    self.wallet = wallet
    self.walletObject = walletObject
  }
  
  func addressType(importType: ImportWalletChainType) -> KAddressType {
    switch importType {
    case .solana:
      return .solana
    default:
      return .evm
    }
  }
  
  func exportMnemonic(account: Account, completion: @escaping (Result<String, KeystoreError>) -> ()) {
    DispatchQueue.global().async {
      let mnemonicResult = self.keystore.exportMnemonics(account: account)
      completion(mnemonicResult)
    }
  }
  
  override func main() {
    DispatchQueue.main.async {
      self.migrate()
    }
  }
  
  func migrate() {
    let chainType = ImportWalletChainType(rawValue: walletObject.chainType) ?? .evm
    let addressType = addressType(importType: chainType)
    
    switch wallet.type {
    case .real(let account):
      switch chainType {
      case .multiChain:
        self.exportMnemonic(account: account) { mnemonicResult in
          switch mnemonicResult {
          case .success(let mnemonic):
            DispatchQueue.main.async {
              if let wallet = try? self.walletManager.import(mnemonic: mnemonic, name: self.walletObject.name) {
                if self.walletObject.isBackedUp {
                    WalletExtraDataManager.shared.markWalletBackedUp(walletID: wallet.id)
                }
              }
              self.finish()
            }
          case .failure:
            self.finish()
          }
        }
        
      case .evm, .solana:
        if let storageType = StorageType(rawValue: walletObject.storateType) {
          switch storageType {
          case .json:
            if let password = self.keystore.getPassword(for: account) {
              let keyResult = self.keystore.exportPrivateKey(account: account)
              switch keyResult {
              case .success(let key):
                self.keystore.keystore(for: key.toHexString(), password: password) { result in
                  switch result {
                  case .success(let json):
                    if let wallet = try? self.walletManager.import(keystore: json, addressType: addressType, password: password, name: self.walletObject.name) {
                      if self.walletObject.isBackedUp {
                          WalletExtraDataManager.shared.markWalletBackedUp(walletID: wallet.id)
                      }
                    }
                  case .failure:
                    ()
                  }
                }
              case .failure:
                ()
              }
            }
          case .privateKey, .unknow:
            let keyResult = self.keystore.exportPrivateKey(account: account)
            switch keyResult {
            case .success(let key):
              if let wallet = try? self.walletManager.import(privateKey: key.toHexString(), addressType: addressType, name: self.walletObject.name) {
                if self.walletObject.isBackedUp {
                    WalletExtraDataManager.shared.markWalletBackedUp(walletID: wallet.id)
                }
              }
            case .failure:
              ()
            }
          default: ()
          }
        }
        self.finish()
      }
    case .solana(_, _, let walletID):
      guard let pk = self.keystore.solanaUtil.exportKeyPair(walletID: walletID) else { return }
      let keypair = SolanaUtil.exportKeyPair(privateKey: pk)
      guard let wallet = try? self.walletManager.import(privateKey: keypair, addressType: .solana, name: self.walletObject.name) else {
        self.finish()
        return
      }
        WalletExtraDataManager.shared.markWalletBackedUp(walletID: wallet.id)
      self.finish()
    case .watch:
      let addressString = walletObject.address
      _ = try? self.walletManager.addWatchWallet(address: addressString, addressType: addressType, name: self.walletObject.name)
      self.finish()
    }
  }
  
  override func finish() {
    onComplete?()
    super.finish()
  }
  
}
