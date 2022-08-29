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
  let walletCache = WalletCache.shared
  let operationQueue = OperationQueue()
  
  init(keystore: Keystore) {
    self.keystore = keystore
    operationQueue.maxConcurrentOperationCount = 1
  }
  
  var needMigrate: Bool {
    if getUnknownWallets().isNotEmpty && UserDefaults.hasMigratedUnknownKeystoreWallet == false {
      return true
    }
    return !UserDefaults.hasMigratedKeystoreWallet && !keystore.wallets.isEmpty
  }
  
  func getUnknownWallets() -> [Wallet] {
    let walletObjects = KNWalletStorage.shared.wallets
    return self.keystore.wallets.filter { wallet in
      guard let walletObject = walletObjects.first(where: { $0.address.lowercased() == wallet.address?.description.lowercased() }) else {
        return false
      }
      switch wallet.type {
      case .real:
        guard let importType = ImportWalletChainType(rawValue: walletObject.chainType) else {
          return false
        }
        let storageType = StorageType(rawValue: walletObject.storateType)
        return (importType == .solana || importType == .solana) && storageType == .unknow
      default:
        return false
      }
    }
  }
  
  func execute(progressCallback: @escaping (Float) -> Void, completion: @escaping () -> Void) {
    if !UserDefaults.hasMigratedKeystoreWallet {
      migrateKeystoreWallets { progress in
        progressCallback(progress)
      } completion: {
        UserDefaults.hasMigratedKeystoreWallet = true
        UserDefaults.hasMigratedUnknownKeystoreWallet = true
        completion()
      }
    }
  }
  
  private func migrateKeystoreWallets(progressCallback: @escaping (Float) -> (), completion: @escaping () -> ()) {
    let totalWallets = keystore.wallets.count
    var completedWallets: Int = 0
    let walletObjects = KNWalletStorage.shared.wallets
    
    let completedOperation = BlockOperation {
      completion()
    }
    self.keystore.wallets.forEach { wallet in
      if let walletObject = walletObjects.first { $0.address.lowercased() == wallet.address?.description.lowercased() } {
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
