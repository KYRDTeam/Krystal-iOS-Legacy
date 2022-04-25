// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

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
    return self.wallets.filter { (object) -> Bool in
      return object.chainType == 2
    }
  }
  
  var nonSolanaWallet: [KNWalletObject] {
    return self.wallets.filter { (object) -> Bool in
      return object.chainType != 2
    }
  }

  func checkAddressExisted(_ address: String) -> Bool {
    let existed = self.wallets.first { (object) -> Bool in
      return object.address.lowercased() == address.lowercased()
    }
    return existed != nil
  }

  func get(forPrimaryKey key: String) -> KNWalletObject? {
    if self.realm == nil { return nil }
    return self.realm.object(ofType: KNWalletObject.self, forPrimaryKey: key)
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
  }

  func deleteAll() {
    if self.realm == nil { return }
    if realm.objects(KNWalletObject.self).isInvalidated { return }
    try! realm.write {
      realm.delete(realm.objects(KNWalletObject.self))
    }
  }
}
