//
//  AppMigrationManager.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/06/2022.
//

import Foundation
import KrystalWallets
import TrustKeystore
import Result

class AppMigrationManager {
  
  let keystore: Keystore
  let walletManager = WalletManager.shared
  let operationQueue = OperationQueue()
  
  init(keystore: Keystore) {
    self.keystore = keystore
    operationQueue.maxConcurrentOperationCount = 1
  }
    
    let unknowWalletsHasMigratedStorageKey = "unknown_wallets_has_been_migrated.data"
    let walletsHasMigratedStorageKey = "wallets_has_been_migrated.data"
  
  var needMigrateUnknownWallets: Bool {
      if Storage.retrieve(unknowWalletsHasMigratedStorageKey, as: Bool.self) ?? false {
          return false
      }
      // Migrate data to storage
      if UserDefaults.hasMigratedUnknownKeystoreWallet {
          Storage.store(true, as: unknowWalletsHasMigratedStorageKey)
          return false
      }
      return getUnknownWallets().isNotEmpty
  }
  
  var needMigrate: Bool {
      if needMigrateUnknownWallets {
          return true
      }
      if Storage.retrieve(walletsHasMigratedStorageKey, as: Bool.self) ?? false {
          return false
      }
      // Migrate data to storage
      if UserDefaults.hasMigratedKeystoreWallet {
          Storage.store(true, as: walletsHasMigratedStorageKey)
          return false
      }
      return !keystore.wallets.isEmpty
  }
  
  func getUnknownWallets() -> [KNWalletObject] {
    return KNWalletStorage.shared.wallets.filter { element in
      return element.storateType == 0
    }
  }
  
  func execute(progressCallback: @escaping (Float) -> Void, completion: @escaping () -> Void) {
      if needMigrate {
          migrateKeystoreWallets { progress in
              progressCallback(progress)
          } completion: {
              Storage.store(true, as: self.walletsHasMigratedStorageKey)
              Storage.store(true, as: self.unknowWalletsHasMigratedStorageKey)
              completion()
          }
      }
  }
  
  private func migrateKeystoreWallets(progressCallback: @escaping (Float) -> (), completion: @escaping () -> ()) {
    KNWalletStorage.shared.migrateUnknownWallets(keystore: keystore, walletObjects: getUnknownWallets().map { $0.clone() })
    let totalWallets = keystore.wallets.count
    var completedWallets: Int = 0
    let walletObjects = KNWalletStorage.shared.wallets
    
    let completedOperation = BlockOperation {
      completion()
    }
    self.keystore.wallets.forEach { wallet in
      if let walletObject = walletObjects.first(where: { $0.address.lowercased() == wallet.address?.description.lowercased() }) {
        let operation = MigratingWalletOperation(keystore: keystore, wallet: wallet, walletObject: walletObject)
        operation.onComplete = {
          DispatchQueue.main.async {
            completedWallets += 1
            progressCallback(Float(completedWallets) / Float(totalWallets))
          }
        }
        operationQueue.addOperation(operation)
      }
    }
    operationQueue.addOperation(completedOperation)
  }
  
  static func migrateCustomNFTIfNeeded() {
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
