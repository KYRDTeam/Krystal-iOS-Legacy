//
//  SolanaUtil.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 19/04/2022.
//

import Foundation
import WalletCore
import SwiftUI
import KeychainSwift

class SolanaUtil {
  
  static let keysSavedKey = "Solana_key_matching"
  
  private let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
  
  let keyStore: KeyStore
  private let keychain: KeychainSwift
  private let defaultKeychainAccess: KeychainSwiftAccessOptions = .accessibleWhenUnlockedThisDeviceOnly
  var keysDict: [String: String] = UserDefaults.standard.object(forKey: SolanaUtil.keysSavedKey) as? [String : String] ?? [:]
  
  init() {
    let keyDirURL = URL(fileURLWithPath: datadir + "/solanaKeyStore")
    self.keyStore = try! KeyStore(keyDirectory: keyDirURL)
    self.keychain = KeychainSwift(keyPrefix: Constants.keychainKeyPrefix)
    self.keychain.synchronizable = false
  }
  
  // Generate seeds to private key object
  static func seedsToPrivateKey(_ seeds: String) -> PrivateKey {
    let hdWallet = HDWallet(mnemonic: seeds, passphrase: "")
    let privateKey = hdWallet!.getKey(coin: .solana, derivationPath: "m/44'/501'/0'/0'")
    return privateKey
  }
  
  // Generate 88 private key from seeds
  static func seedsToKeyPair(_ seeds: String) -> String {
    let privateKey = SolanaUtil.seedsToPrivateKey(seeds)
    let publicKey = privateKey.getPublicKeyEd25519()
    let privateKeyData = privateKey.data
    let publicKeyData = publicKey.data
    
    let data = privateKeyData + publicKeyData
    let keyPairString = Base58.encodeNoCheck(data: data)
    return keyPairString
  }

  static func seedsToPublicKey(_ seeds: String) -> String {
    let privateKey = SolanaUtil.seedsToPrivateKey(seeds)
    let publicKey = privateKey.getPublicKeyEd25519()
    var solanaAddress = AnyAddress(publicKey: publicKey, coin: .solana)
    return solanaAddress.description
  }
  
  // Generate privateKey from keypair
  static func keyPairToPrivateKey(_ keypair: String) -> PrivateKey? {
    guard let data = Base58.decodeNoCheck(string: keypair) else { return nil }
    let key = PrivateKey(data: data[0...31])
    return key
  }
  
  static func keyPairToPrivateKeyData(_ keypair: String) -> Data? {
    let data = SolanaUtil.keyPairToPrivateKey(keypair)?.data
    return data
  }
  
  static func signTransferTransaction(privateKeyData: Data, recipient: String, value: UInt64, recentBlockhash: String) -> String {
    let transferMessage = SolanaTransfer.with {
      $0.recipient = recipient
      $0.value = value
    }
    let input = SolanaSigningInput.with {
      $0.transferTransaction = transferMessage
      $0.recentBlockhash = recentBlockhash
      $0.privateKey = privateKeyData
    }
    
    let output: SolanaSigningOutput = AnySigner.sign(input: input, coin: .solana)
    return output.encoded
  }
  
  func getPassword(for account: WalletCore.Wallet) -> String? {
      let key = keychainKey(for: account)
      return keychain.get(key)
  }

  @discardableResult
  func setPassword(_ password: String, for account:  WalletCore.Wallet) -> Bool {
      let key = keychainKey(for: account)
      return keychain.set(password, forKey: key, withAccess: defaultKeychainAccess)
  }

  internal func keychainKey(for account: WalletCore.Wallet) -> String {
      return account.identifier
  }
  
  func importKeyPair(_ key: String) -> (String?, WalletCore.Account?) {
    guard let pk = SolanaUtil.keyPairToPrivateKey(key) else {
      return (nil, nil)
    }
    let newPassword = PasswordGenerator.generateRandom()
    let wallet = try? self.keyStore.import(privateKey: pk, name: "", password: newPassword, coin: .ethereum)
    if let unwrap = wallet {
      self.setPassword(newPassword, for: unwrap)
      let address = AnyAddress(publicKey: pk.getPublicKeyEd25519(), coin: .solana)
      self.keysDict[address.description] = unwrap.identifier
      let account = try! unwrap.getAccount(password: newPassword, coin: .ethereum)
      return (address.description, account)
    }
    
    return (nil, nil)
  }
  
  func getPrivateKeyForAddress(_ address: String) -> PrivateKey? {
    guard let walletID = self.keysDict[address] else {
      return nil
    }
    let filter = self.keyStore.wallets.first { element in
      return element.identifier == walletID
    }
    
    if let unwrap = filter, let password = self.getPassword(for: unwrap) {
      
      let data = try! self.keyStore.exportPrivateKey(wallet: unwrap, password: password)
      let pk = PrivateKey(data: data)
      return pk
    }
    
    return nil
  }
}
