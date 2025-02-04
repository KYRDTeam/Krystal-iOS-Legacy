// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

enum StorageType: Int {
  case unknow = 0
  case json
  case privateKey
  case seeds
  case watch
}

class KNWalletObject: Object {

  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var icon: String = ""
  @objc dynamic var isBackedUp: Bool = true
  @objc dynamic var isWatchWallet: Bool = false
  @objc dynamic var date: Date = Date()
  @objc dynamic var chainType: Int = 0
  @objc dynamic var storateType: Int = 0
  @objc dynamic var evmAddress: String = ""
  @objc dynamic var solanaAddress: String = ""
  @objc dynamic var walletID: String = ""

  convenience init(address: String, name: String = "Untitled", isBackedUp: Bool = false, isWatchWallet: Bool = false, chainType: ImportWalletChainType = .multiChain, storageType: StorageType = .unknow, evmAddress: String = "", solanaAddress: String = "", walletID: String = "") {
    self.init()
    self.address = address
    self.name = name
    self.icon = ""
    self.date = Date()
    self.isBackedUp = isBackedUp
    self.isWatchWallet = isWatchWallet
    self.chainType = chainType.rawValue
    self.storateType = storageType.rawValue
    self.evmAddress = evmAddress
    self.solanaAddress = solanaAddress
    self.walletID = walletID
  }

  convenience init(address: String, name: String, icon: String, date: Date, isBackedUp: Bool = false, isWatchWallet: Bool, chainType: ImportWalletChainType, storageType: StorageType = .unknow, evmAddress: String = "", solanaAddress: String = "", walletID: String = "") {
    self.init()
    self.address = address
    self.name = name
    self.icon = icon
    self.date = date
    self.isBackedUp = isBackedUp
    self.isWatchWallet = isWatchWallet
    self.chainType = chainType.rawValue
    self.storateType = storageType.rawValue
    self.evmAddress = evmAddress
    self.solanaAddress = solanaAddress
    self.walletID = walletID
  }

  func copy(withNewName newName: String) -> KNWalletObject {
    return KNWalletObject(
      address: self.address,
      name: newName,
      icon: self.icon,
      date: self.date,
      isBackedUp: self.isBackedUp,
      isWatchWallet: self.isWatchWallet,
      chainType: ImportWalletChainType(rawValue: self.chainType)!,
      storageType: StorageType(rawValue: self.storateType)!,
      evmAddress: self.evmAddress,
      solanaAddress: self.solanaAddress,
      walletID: self.walletID
    )
  }

  override class func primaryKey() -> String? {
    return "address"
  }

  func clone() -> KNWalletObject {
    return KNWalletObject(
      address: self.address,
      name: self.name,
      icon: self.icon,
      date: self.date,
      isBackedUp: self.isBackedUp,
      isWatchWallet: self.isWatchWallet,
      chainType: ImportWalletChainType(rawValue: self.chainType)!,
      storageType: StorageType(rawValue: self.storateType)!,
      evmAddress: self.evmAddress,
      solanaAddress: self.solanaAddress,
      walletID: self.walletID
    )
  }

  func toData() -> WalletData {
    return WalletData(
      address: self.address,
      name: self.name,
      icon: self.icon,
      isBackedUp: self.isBackedUp,
      isWatchWallet: self.isWatchWallet,
      date: self.date,
      chainType: ImportWalletChainType(rawValue: self.chainType)!,
      storageType: StorageType(rawValue: self.storateType)!,
      evmAddress: self.evmAddress,
      solanaAddress: self.solanaAddress,
      walletID: self.walletID
    )
  }

  func getWalletChainType() -> ImportWalletChainType {
    return ImportWalletChainType(rawValue: self.chainType) ?? .multiChain
  }
  
  func toSolanaWallet() -> Wallet {
    if self.isWatchWallet {
      return Wallet(type: .solana(self.address, self.evmAddress, self.walletID))
    }
    return Wallet(type: .solana(self.solanaAddress, self.evmAddress, self.walletID))
  }
  
  func toSolanaWalletObject() -> KNWalletObject {
    return KNWalletObject(
      address: self.solanaAddress,
      name: self.name,
      icon: self.icon,
      date: self.date,
      isBackedUp: self.isBackedUp,
      isWatchWallet: self.isWatchWallet,
      chainType: .solana,
      storageType: StorageType(rawValue: self.storateType)!,
      evmAddress: self.evmAddress,
      solanaAddress: self.solanaAddress,
      walletID: self.walletID
    )
  }
  
  func isNeedMigration() -> Bool {
    return self.chainType == 0 && self.storateType == 0 && self.evmAddress.isEmpty && self.walletID.isEmpty
  }
}

class KNWalletPromoInfoStorage: NSObject {

  let userDefaults = UserDefaults.standard
  let destAddressKey = "destAddressKey"
  let expiredTimeKey = "expiredTimeKey"
  static let shared = KNWalletPromoInfoStorage()
  var kKeyPrefix: String {
    return "\(KNEnvironment.default.displayName)_\(KNGeneralProvider.shared.customRPC.chainID)_"
  }

  override init() {}

  func addWalletPromoInfo(address: String, destinationToken: String, destAddress: String?, expiredTime: TimeInterval) {
    self.userDefaults.set(destinationToken, forKey: kKeyPrefix + address.lowercased())
    if let destAddr = destAddress {
      self.userDefaults.set(destAddr, forKey: kKeyPrefix + destAddressKey + address.lowercased())
    } else {
      self.userDefaults.removeObject(forKey: kKeyPrefix + destAddressKey + address.lowercased())
    }
    self.userDefaults.set(expiredTime, forKey: kKeyPrefix + expiredTimeKey + address.lowercased())
    self.userDefaults.synchronize()
  }

  func removeWalletPromoInfo(address: String) {
    self.userDefaults.removeObject(forKey: kKeyPrefix + address.lowercased())
    self.userDefaults.removeObject(forKey: kKeyPrefix + destAddressKey + address.lowercased())
    self.userDefaults.removeObject(forKey: kKeyPrefix + expiredTimeKey + address.lowercased())
    self.userDefaults.synchronize()
  }

  func getDestinationToken(from address: String) -> String? {
    return self.userDefaults.object(forKey: kKeyPrefix + address.lowercased()) as? String
  }

  func getDestWallet(from address: String) -> String? {
    return self.userDefaults.object(forKey: kKeyPrefix + destAddressKey + address.lowercased()) as? String
  }

  func getExpiredTime(from address: String) -> TimeInterval? {
    return self.userDefaults.object(forKey: kKeyPrefix + expiredTimeKey + address.lowercased()) as? TimeInterval
  }
}
