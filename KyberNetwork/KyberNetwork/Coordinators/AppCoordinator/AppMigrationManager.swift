//
//  AppMigrationManager.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/06/2022.
//

import Foundation
import KrystalWallets

class AppMigrationManager {
  
  let keystore: Keystore
  let walletManager = WalletManager.shared
  let walletCache = WalletCache.shared
  
  init(keystore: Keystore) {
    self.keystore = keystore
  }
  
  func execute() {
    if !UserDefaults.hasMigratedKeystoreWallet {
      migrateKeystoreWallets()
      UserDefaults.hasMigratedKeystoreWallet = true
    }
    self.migrateCustomNFTIfNeeded()
  }
  
  private func migrateKeystoreWallets() {
    keystore.wallets.forEach { wallet in
      if let walletObject = wallet.getWalletObject() {
        let chainType = ImportWalletChainType(rawValue: walletObject.chainType)
        let addressType: KAddressType = {
          switch chainType {
          case .solana:
            return .solana
          default:
            return .evm
          }
        }()
        switch wallet.type {
        case .real(let account):
          switch chainType {
          case .multiChain:
            let mnemonicResult = self.keystore.exportMnemonics(account: account)
            switch mnemonicResult {
            case .success(let mnemonic):
              if let wallet = try? self.walletManager.import(mnemonic: mnemonic, name: walletObject.name) {
                if walletObject.isBackedUp {
                  self.walletCache.markWalletBackedUp(walletID: wallet.id)
                }
              }
            case .failure:
              ()
            }
          case .evm, .solana:
            if let storageType = StorageType(rawValue: walletObject.storateType) {
              switch storageType {
              case .json:
                if let password = keystore.getPassword(for: account) {
                  let keyResult = self.keystore.exportPrivateKey(account: account)
                  switch keyResult {
                  case .success(let key):
                    self.keystore.keystore(for: key.toHexString(), password: password) { result in
                      switch result {
                      case .success(let json):
                        if let wallet = try? self.walletManager.import(keystore: json, addressType: addressType, password: password, name: walletObject.name) {
                          if walletObject.isBackedUp {
                            self.walletCache.markWalletBackedUp(walletID: wallet.id)
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
              case .privateKey:
                let keyResult = self.keystore.exportPrivateKey(account: account)
                switch keyResult {
                case .success(let key):
                  if let wallet = try? self.walletManager.import(privateKey: key.toHexString(), addressType: addressType, name: walletObject.name) {
                    if walletObject.isBackedUp {
                      self.walletCache.markWalletBackedUp(walletID: wallet.id)
                    }
                  }
                case .failure:
                  ()
                }
              default: ()
              }
            }
          default:
            return
          }
        case .solana(_, _, let walletID):
          guard let pk = self.keystore.solanaUtil.exportKeyPair(walletID: walletID) else { return }
          let keypair = SolanaUtil.exportKeyPair(privateKey: pk)
          _ = try? self.walletManager.import(privateKey: keypair, addressType: .solana, name: walletObject.name)
        case .watch:
          let addressString = walletObject.address
          _ = try? self.walletManager.addWatchWallet(address: addressString, addressType: addressType, name: walletObject.name)
          return
        }
      }
    }
  }
  
  private func migrateCustomNFTIfNeeded() {
    let allChain = ChainType.getAllChain()
    let address = AppDelegate.session.address.addressString
    let filePaths = allChain.map { e in
      return e.getChainDBPath() + address + Constants.summaryChainStoreFileName
    }
    
    var existsData = false
    
    filePaths.forEach { e in
      if Storage.isFileExistAtPath(e) {
        existsData = true
      }
    }
    
    guard existsData else {
      return
    }
    
    var customSections: [NFTSection] = []
    
    for (index, element) in filePaths.enumerated() {
      if let data = Storage.retrieve(element, as: [NFTSection].self) {
        data.forEach { e in
          e.chainType = allChain[index]
        }
        customSections.append(contentsOf: data)
        Storage.removeFileAtPath(element)
      }
    }
    
    Storage.store(customSections, as: address + Constants.customNftBalanceStoreFileName)
  }
  
}
