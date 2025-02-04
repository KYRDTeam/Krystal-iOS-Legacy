// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt
import OneSignal
import UIKit

class KNWalletStorage {

  static var shared = KNWalletStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var wallets: [KNWalletObject] {
    if self.realm == nil { return [] }
    if self.realm.objects(KNWalletObject.self).isInvalidated { return [] }
    return self.realm.objects(KNWalletObject.self)
      .filter { return !$0.address.isEmpty }
  }
  
  var cloneWallets: [KNWalletObject] {
    return self.wallets.map { element in
      return element.clone()
    }
  }

  var watchWallets: [KNWalletObject] {
    return self.wallets.filter { (object) -> Bool in
      return object.isWatchWallet
    }
  }

  var realWallets: [KNWalletObject] {
    return self.wallets.filter { (object) -> Bool in
      return !object.isWatchWallet
    }
  }
  
  var solanaWallet: [KNWalletObject] {
    let allWallets = self.wallets
    let solWallets = allWallets.filter { (object) -> Bool in
      return object.chainType == 2
    }
    
    let multichainWallet = allWallets.filter { (object) -> Bool in
      return object.chainType == 0
    }
    
    return solWallets + multichainWallet
  }
  
  var nonSolanaWallet: [KNWalletObject] {
    return self.wallets.filter { (object) -> Bool in
      return object.chainType != 2
    }
  }
  
  var onlySolanaWallet: [KNWalletObject] {
    let allWallets = self.wallets
    let solWallets = allWallets.filter { (object) -> Bool in
      return object.chainType == 2
    }
    return solWallets
  }

  func checkAddressExisted(_ address: String) -> Bool {
    let existed = self.wallets.first { (object) -> Bool in
      return object.address.lowercased() == address.lowercased()
    }
    return existed != nil
  }
  
  func checkSolanaAddressExisted(_ address: String) -> Bool {
    let existed = self.get(forSolanaAddress: address)
    return existed != nil
  }
  
  func get(forSolanaAddress address: String) -> KNWalletObject? {
    let existed = self.wallets.first { (object) -> Bool in
      return object.solanaAddress == address
    }
    return existed
  }
  
  var availableWalletObjects: [KNWalletObject] {
    return self.getAvailableWalletForChain(KNGeneralProvider.shared.currentChain)
  }

  func getAvailableWalletForChain(_ chain: ChainType) -> [KNWalletObject] {
    let allWallets = self.wallets
    if chain == .solana {
      let solWallets = allWallets.filter { (object) -> Bool in
        return object.chainType == 2
      }
      
      let multichainWallet = allWallets.filter { (object) -> Bool in
        return object.chainType == 0
      }
      
      let solFromMultichainWallet = multichainWallet.map { element in
        return element.toSolanaWalletObject()
      }
      
      return solWallets + solFromMultichainWallet
    } else {
      return allWallets.filter { $0.chainType != 2 } 
    }
  }

  func get(forPrimaryKey key: String) -> KNWalletObject? {
    if self.realm == nil { return nil }
    return self.realm.object(ofType: KNWalletObject.self, forPrimaryKey: key)
  }
  
  func getAvailableWalletObject(forPrimaryKey key: String) -> KNWalletObject? {
    return self.availableWalletObjects.first { element in
      return element.address == key
    }
  }

  func add(wallets: [KNWalletObject]) {
    if self.realm == nil { return }
    if realm.objects(KNWalletObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add(wallets, update: .modified)
    try! self.realm.commitWrite()
  }

  func update(wallets: [KNWalletObject]) {
    self.add(wallets: wallets)
  }

  func delete(wallet: KNWalletObject) {
    if self.realm == nil { return }
    if realm.objects(KNWalletObject.self).isInvalidated { return }
    self.realm.beginWrite()
    
    if let obj = self.get(forPrimaryKey: wallet.address) {
      self.realm.delete(obj)
    }
    
    try! self.realm.commitWrite()
    
    //Check empty storage
    if self.wallets.isEmpty {
      OneSignal.removeExternalUserId()
    }
  }

  func deleteAll() {
    if self.realm == nil { return }
    if realm.objects(KNWalletObject.self).isInvalidated { return }
    try! realm.write {
      realm.delete(realm.objects(KNWalletObject.self))
    }
  }
  
  func delete(walletAddress: String) {
    if self.realm == nil { return }
    guard let obj = self.get(forPrimaryKey: walletAddress), !obj.isInvalidated else { return }
    if realm.objects(KNWalletObject.self).isInvalidated { return }
    self.realm.beginWrite()
    
    self.realm.delete(obj)
    
    try! self.realm.commitWrite()
  }
  
  func migrateDataIfNeeded(keyStore: Keystore) {
    let found = self.wallets.filter { element in
      return element.isNeedMigration()
    }
    
    guard found.isNotEmpty else { return }
    let clones = found.map { element in
      return element.clone()
    }
    let vc = UIApplication.shared.keyWindow?.rootViewController
    vc?.displayLoading(text: "Migrating", animated: true)
    DispatchQueue.main.async {
      self.migrateUnknownWallets(keystore: keyStore, walletObjects: clones)
      vc?.hideLoading()
    }
  }
  
  func migrateUnknownWallets(keystore: Keystore, walletObjects: [KNWalletObject]) {
    walletObjects.forEach { obj in
      if let account = keystore.matchWithEvmAccount(address: obj.address.lowercased()), case .success(let seeds) = keystore.exportMnemonics(account: account) {
        let solAddress = SolanaUtil.seedsToPublicKey(seeds)
        obj.evmAddress = obj.address
        obj.solanaAddress = solAddress
      } else {
        obj.chainType = 1
        obj.evmAddress = obj.address
      }
    }
    self.update(wallets: walletObjects)
  }
}
