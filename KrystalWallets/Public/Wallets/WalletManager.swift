//
//  WalletManager.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation
import WalletCore
import RealmSwift

public class WalletManager {
  
  public static let shared = WalletManager()
  let keyDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/wallets")
  let keyManager: KeyManager
  
  private init() {
    keystore = try! KeyStore(keyDirectory: keyDirectory)
    keyManager = KeyManager()
  }
  
  let keystore: KeyStore
  
  var supportedAddressTypes: [KAddressType] = [.evm, .solana]
}

// Public functions
public extension WalletManager {
  
  func getAddress(id: String) -> KAddress? {
    let realm = try! Realm()
    return realm.objects(AddressObject.self)
      .filter("%K = %@", "id", id)
      .first?.toAddress()
  }
  
  func address(forWalletID walletID: String) -> KAddress? {
    return getAllAddresses(walletID: walletID).first
  }
  
  func watchAddresses() -> [KAddress] {
    return getAllAddresses(walletID: "")
  }
  
  func getWallet(id: String) -> KWallet? {
    return getAllWallets().first { $0.id == id }
  }
  
  func getAllWallets() -> [KWallet] {
    let realm = try! Realm()
    return realm.objects(WalletObject.self).map { $0.toWallet() }
  }
  
  func getAllAddresses() -> [KAddress] {
    let realm = try! Realm()
    return realm.objects(AddressObject.self).map { $0.toAddress() }
  }
  
  func getAllAddresses(addressType: KAddressType) -> [KAddress] {
    let realm = try! Realm()
    return realm.objects(AddressObject.self)
      .filter("%K = %@", "addressType", addressType.rawValue)
      .map { $0.toAddress() }
  }
  
  func getAllAddresses(walletID: String) -> [KAddress] {
    let realm = try! Realm()
    return realm.objects(AddressObject.self)
      .filter("%K = %@", "walletID", walletID)
      .map { $0.toAddress() }
  }
  
  func getAllAddresses(walletID: String, addressType: KAddressType) -> [KAddress] {
    let realm = try! Realm()
    return realm.objects(AddressObject.self)
      .filter("%K = %@ and %K = %@", "walletID", walletID, "addressType", addressType.rawValue)
      .map { $0.toAddress() }
  }
  
  func getAllAddresses(addresses: [String]) -> [KAddress] {
    let realm = try! Realm()
    let kAddresses = realm.objects(AddressObject.self)
          .filter("%K IN %@", "address", addresses + addresses.map { $0.lowercased() })
          .map { $0.toAddress() }
    return kAddresses.map { $0 }
  }

  func wallet(forAddress address: KAddress) -> KWallet? {
    let realm = try! Realm()
    return realm.objects(WalletObject.self)
      .filter("%K = %@", "id", address.walletID)
      .map { $0.toWallet() }
      .first
  }
  
  //Quickfix crash
  func getWalletWithLocalRealm(forAddress address: KAddress) -> KWallet? {
    let realm = try! Realm()
    return realm.objects(WalletObject.self)
      .filter("%K = %@", "id", address.walletID)
      .map { $0.toWallet() }
      .first
  }
  
  func getAllAddressesWithLocalRealm(walletID: String, addressType: KAddressType) -> [KAddress] {
    let realm = try! Realm()
    return realm.objects(AddressObject.self)
      .filter("%K = %@ and %K = %@", "walletID", walletID, "addressType", addressType.rawValue)
      .map { $0.toAddress() }
  }
  
  func createWallet(name: String) throws -> KWallet {
    do {
      let password = PasswordGenerator.generateRandom()
      let wallet = try keystore.createWallet(name: name, password: password, coins: supportedAddressTypes.map(\.coinType))
      keyManager.save(value: password, forKey: wallet.identifier)
      let walletObject = WalletObject(id: wallet.identifier, importType: .mnemonic, name: name)
      
      let addresses = try supportedAddressTypes.map { addressType -> AddressObject in
        let privateKey = try getPrivateKey(wallet: walletObject.toWallet(), forAddressType: addressType)
        let address = getAddress(privateKey: privateKey, addressType: addressType)
        return AddressObject(walletID: walletObject.id, addressType: addressType, address: address, name: name)
      }
      let realm = try! Realm()
      try realm.write {
        realm.add(walletObject)
        realm.add(addresses)
      }
      return walletObject.toWallet()
    } catch {
      throw WalletManagerError.cannotImportWallet
    }
  }
  
  func createEmptyAddress() -> KAddress {
    return KAddress(id: "", walletID: "", addressType: .evm, name: "", addressString: "")
  }
  
  func `import`(keystore: String, addressType: KAddressType, password: String, name: String) throws -> KWallet {
    do {
      guard let json = keystore.data(using: .utf8) else {
        throw WalletManagerError.invalidJSON
      }
      let newPassword = PasswordGenerator.generateRandom()
      let importedWallet = try self.keystore.import(json: json, name: name, password: password, newPassword: newPassword, coins: [addressType.coinType])
      keyManager.save(value: newPassword, forKey: importedWallet.identifier)
      let wallet = WalletObject(id: importedWallet.identifier, importType: .privateKey, name: name)
      let account = try importedWallet.getAccount(password: "", coin: addressType.coinType)
        let address = AddressObject(walletID: wallet.id, addressType: addressType, address: account.address.lowercased(), name: name)
      
      let existedAddresses = self.getAllAddresses(addresses: [account.address])
        
        if existedAddresses.count > 0, !existedAddresses[0].isWatchWallet {
            throw WalletManagerError.duplicatedWallet
        }
        
        existedAddresses.forEach { address in
            try? removeAddress(address: address)
        }
        
      let realm = try! Realm()
      try realm.write {
        realm.add(wallet)
        realm.add(address)
      }
      return wallet.toWallet()
    } catch {
      throw error
    }
  }
  
  func `import`(privateKey: String, addressType: KAddressType, name: String) throws -> KWallet {
    guard let key = createPrivateKey(fromString: privateKey, addressType: addressType) else {
      throw WalletManagerError.invalidPrivateKey
    }
    do {
      let password = PasswordGenerator.generateRandom()
      let importedWallet = try keystore.import(privateKey: key, name: name, password: password, coin: addressType.coinType)
      keyManager.save(value: password, forKey: importedWallet.identifier)
      
      let wallet = WalletObject(id: importedWallet.identifier, importType: .privateKey, name: name)
      let address = getAddress(privateKey: key, addressType: addressType)
      let addressObject = AddressObject(walletID: wallet.id, addressType: addressType, address: address, name: name)
      
      let existedAddresses = self.getAllAddresses(addresses: [address])
      
        if existedAddresses.count > 0, !existedAddresses[0].isWatchWallet {
            throw WalletManagerError.duplicatedWallet
        }
        
        existedAddresses.forEach { address in
            try? removeAddress(address: address)
        }
        
      let realm = try! Realm()
      try realm.write {
        realm.add(wallet)
        realm.add(addressObject)
      }
      return wallet.toWallet()
    } catch {
      throw error
    }
  }
  
  func `import`(mnemonic: String, name: String) throws -> KWallet {
    do {
      let password = PasswordGenerator.generateRandom()
      let wallet = try keystore.import(mnemonic: mnemonic, name: name, encryptPassword: password, coins: supportedAddressTypes.map(\.coinType))
      let walletObject = WalletObject(id: wallet.identifier, importType: .mnemonic, name: name)
      keyManager.save(value: password, forKey: wallet.identifier)
      let addresses = try supportedAddressTypes.map { addressType -> AddressObject in
        let privateKey = try getPrivateKey(wallet: walletObject.toWallet(), forAddressType: addressType)
        let address = getAddress(privateKey: privateKey, addressType: addressType)
        return AddressObject(walletID: walletObject.id, addressType: addressType, address: address, name: name)
      }
      
      let existedAddresses = self.getAllAddresses(addresses: addresses.map(\.address))
      
        if existedAddresses.count > 0, !existedAddresses[0].isWatchWallet {
            throw WalletManagerError.duplicatedWallet
        }
        
        existedAddresses.forEach { address in
            try? removeAddress(address: address)
        }
        
      let realm = try! Realm()
      try realm.write {
        realm.add(walletObject)
        realm.add(addresses)
      }
      return walletObject.toWallet()
    } catch {
      throw error
    }
  }
  
  func isWatchAddressExisted(address: String) -> Bool {
    return watchAddresses().contains { $0.addressString == address }
  }
  
  func validateAddress(address: String, forAddressType addressType: KAddressType) -> Bool {
    return addressType.coinType.validate(address: address)
  }
  
  func addWatchWallet(address: String, addressType: KAddressType, name: String) throws -> KAddress {
    let addressObject = AddressObject(walletID: "", addressType: addressType, address: address, name: name)
    let existedAddresses = self.getAllAddresses(addresses: [address])
    
    guard existedAddresses.isEmpty else {
      throw WalletManagerError.duplicatedWallet
    }
    
    do {
      let realm = try! Realm()
      try realm.write {
        realm.add(addressObject)
      }
      return addressObject.toAddress()
    } catch {
      throw error
    }
  }
  
  func exportMnemonic(walletID: String) throws -> String {
    let realm = try! Realm()
    guard let wallet = realm.object(ofType: WalletObject.self, forPrimaryKey: walletID)?.toWallet() else {
      throw WalletManagerError.cannotFindWallet
    }
    guard let savedWallet = keystore.wallets.first(where: { $0.identifier == wallet.id }) else {
      throw WalletManagerError.cannotFindWallet
    }
    
    do {
      guard let password = keyManager.value(forKey: savedWallet.identifier) else {
        throw WalletManagerError.cannotExportMnemonic
      }
      let mnemonic = try keystore.exportMnemonic(wallet: savedWallet, password: password)
      return mnemonic
    } catch {
      throw WalletManagerError.cannotExportMnemonic
    }
  }
  
  func exportPrivateKey(walletID: String, addressType: KAddressType) throws -> String {
    let realm = try! Realm()
    guard let wallet = realm.object(ofType: WalletObject.self, forPrimaryKey: walletID)?.toWallet() else {
      throw WalletManagerError.cannotFindWallet
    }
    do {
      let key = try getPrivateKey(wallet: wallet, forAddressType: addressType)
      return WalletUtils.string(fromPrivateKey: key, addressType: addressType)
    } catch {
      throw WalletManagerError.cannotExportPrivateKey
    }
  }
  
  func exportPrivateKey(address: KAddress) throws -> String {
    return try exportPrivateKey(walletID: address.walletID, addressType: address.addressType)
  }
  
  func exportKeystore(address: KAddress, password: String) throws -> String {
    let privateKey = try exportPrivateKey(address: address)
    guard let data = Data(hexString: privateKey) else {
      throw WalletManagerError.cannotExportKeystore
    }
    guard let data = StoredKey.importPrivateKey(privateKey: data, name: "", password: Data(password.utf8), coin: address.addressType.coinType)?.exportJSON() else {
      throw WalletManagerError.cannotExportKeystore
    }
    let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    return dict.jsonString ?? ""
  }
  
  func address(walletID: String, addressType: KAddressType) -> KAddress? {
    let realm = try! Realm()
    return realm.objects(AddressObject.self)
      .filter("%K = %@ AND %K = %@", "addressType", addressType.rawValue, "walletID", walletID)
      .map { $0.toAddress() }
      .first
  }
  
  func removeAddress(address: KAddress) throws {
    let realm = try! Realm()
    let addressObjects = realm.objects(AddressObject.self)
      .filter("%K = %@ AND %K = %@",
              "address", address.addressString,
              "addressType", address.addressType.rawValue
      )
    do {
      try realm.write {
        realm.delete(addressObjects)
      }
    } catch {
      throw WalletManagerError.failedToRemoveAddress
    }
  }
  
  func remove(wallet: KWallet) throws {
    let realm = try! Realm()
    let walletObjects = realm.objects(WalletObject.self)
      .filter("%K = %@", "id", wallet.id)
    let addressObjects = realm.objects(AddressObject.self)
      .filter("%K = %@", "walletID", wallet.id)
    do {
      try realm.write {
        realm.delete(addressObjects)
        realm.delete(walletObjects)
      }
      guard let keystoreWallet = keystore.wallets.first(where: { $0.identifier == wallet.id }) else {
        return
      }
      guard let password = keyManager.value(forKey: wallet.id) else {
        return
      }
      try keystore.delete(wallet: keystoreWallet, password: password)
    } catch {
      throw WalletManagerError.failedToRemoveWallet
    }
  }
  
  func updateWatchAddress(address: KAddress) throws {
    let realm = try! Realm()
    let addressObjects = realm.objects(AddressObject.self)
      .filter("%K = %@", "id", address.id)
    
    do {
      try realm.write {
        addressObjects.forEach { object in
          object.name = address.name
          object.address = address.addressString
          object.addressType = address.addressType.rawValue
          object.walletID = address.walletID
        }
      }
    } catch {
      throw WalletManagerError.failedToUpdateAddress
    }
  }
  
  func renameWallet(wallet: KWallet, newName: String) throws {
    let realm = try! Realm()
    let addressObjects = realm.objects(AddressObject.self)
      .filter("%K = %@", "walletID", wallet.id)
    let walletObjects = realm.objects(WalletObject.self)
      .filter("%K = %@", "id", wallet.id)
    do {
      try realm.write {
        addressObjects.forEach { address in
          address.name = newName
        }
        walletObjects.forEach { wallet in
          wallet.name = newName
        }
      }
    } catch {
      throw WalletManagerError.failedToRenameWallet
    }
  }
  
  func removeAll() {
    let realm = try! Realm()
    keystore.wallets.forEach { wallet in
      if let password = keyManager.value(forKey: wallet.identifier) {
        try? keystore.delete(wallet: wallet, password: password)
      }
    }
    try? realm.write {
      realm.deleteAll()
    }
  }
  
}

extension WalletManager {
  
  func getAddress(privateKey: PrivateKey, addressType: KAddressType) -> String {
    switch addressType {
    case .evm:
      return addressType.coinType.deriveAddress(privateKey: privateKey).lowercased()
    case .solana:
      let address = AnyAddress(publicKey: privateKey.getPublicKeyEd25519(), coin: .solana)
      return address.description
    }
  }
  
  func getPrivateKey(wallet: KWallet, forAddressType addressType: KAddressType) throws -> PrivateKey {
    guard let storedWallet = keystore.wallets.first(where: { $0.identifier == wallet.id }) else {
      throw WalletManagerError.cannotExportPrivateKey
    }
    guard let password = keyManager.value(forKey: storedWallet.identifier) else {
      throw WalletManagerError.cannotExportPrivateKey
    }
    switch wallet.importType {
    case .mnemonic:
      let mnemonic = try keystore.exportMnemonic(wallet: storedWallet, password: password)
      guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
        throw WalletManagerError.cannotExportPrivateKey
      }
      switch addressType {
      case .evm:
        return hdWallet.getKeyForCoin(coin: .ethereum)
      case .solana:
        let key = hdWallet.getKey(coin: .solana, derivationPath: "m/44'/501'/0'/0'")
        return key
      }
    case .privateKey:
      guard let privateKey = try PrivateKey(data: keystore.exportPrivateKey(wallet: storedWallet, password: password)) else {
        throw WalletManagerError.cannotExportPrivateKey
      }
      return privateKey
    }
  }
  
  func createPrivateKey(fromString string: String, addressType: KAddressType) -> PrivateKey? {
    switch addressType {
    case .evm:
      guard let data = Data(hexString: string) else {
        return nil
      }
      return PrivateKey(data: data)
    case .solana:
      guard let data = Base58.decodeNoCheck(string: string) else {
        return nil
      }
      let key = PrivateKey(data: data[0...31])
      return key
    }
  }
  
}
