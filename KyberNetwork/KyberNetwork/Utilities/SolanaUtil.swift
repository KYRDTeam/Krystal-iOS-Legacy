//
//  SolanaUtil.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 19/04/2022.
//

import Foundation
import WalletCore
import KeychainSwift
import Moya
import BigInt

@available(*, deprecated, message: "Use KrystalWallets.WalletManager instead")
class SolanaUtil {
  
  static let keysSavedKey = "Solana_key_matching"
  
  private let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
  
  let keyStore: KeyStore
  private let keychain: KeychainSwift
  private let defaultKeychainAccess: KeychainSwiftAccessOptions = .accessibleWhenUnlockedThisDeviceOnly
  var keysDict: [String: String] = UserDefaults.standard.object(forKey: SolanaUtil.keysSavedKey) as? [String: String] ?? [:]
  
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
  
  static func soletSeedsToPrivateKey(_ seeds: String) -> PrivateKey? {
    let path = "m/44'/501'/0'/0'"
    let hdWal = HDWallet(mnemonic: seeds, passphrase: "")
    let pk = hdWal?.getKey(coin: .solana, derivationPath: path)
    return pk
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
    let solanaAddress = AnyAddress(publicKey: publicKey, coin: .solana)
    return solanaAddress.description
  }
  
  // Generate privateKey from keypair
  static func keyPairToPrivateKey(_ keypair: String) -> PrivateKey? {
    if keypair.isTrustPK {
      guard let data = Data(hexString: keypair) else { return nil }
      let privateKey = PrivateKey(data: data[0...31])
      return privateKey
    } else {
      guard let data = Base58.decodeNoCheck(string: keypair) else { return nil }
      let key = PrivateKey(data: data[0...31])
      return key
    }
  }

  static func keyPairToPrivateKeyData(_ keypair: String) -> Data? {
    let data = SolanaUtil.keyPairToPrivateKey(keypair)?.data
    return data
  }
  
  static func generateTokenAccountAddress(receiptWalletAddress: String, tokenMintAddress: String) -> String {
    return SolanaAddress(string: receiptWalletAddress)?.defaultTokenAddress(tokenMintAddress: tokenMintAddress) ?? ""
  }
  
  static func soletStringToPrivateKey(_ key: String) -> PrivateKey? {
    guard key.isSoletPKVaild else { return nil }
    let stringList = key.dropFirst().dropLast().split(separator: ",").map { item in
      return UInt8(item) ?? 0
    }
    let data = Data(bytes: stringList)
    let privateKey = PrivateKey(data: data[0...31])
    return privateKey
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
  
  static func signTokenTransferTransaction(tokenMintAddress: String, senderTokenAddress: String, privateKeyData: Data, recipientTokenAddress: String, amount: UInt64, recentBlockhash: String, tokenDecimals: UInt32) -> String {
    let tokenTransferMessage = SolanaTokenTransfer.with {
      $0.tokenMintAddress = tokenMintAddress
      $0.senderTokenAddress = senderTokenAddress
      $0.recipientTokenAddress = recipientTokenAddress
      $0.amount = amount
      $0.decimals = tokenDecimals
    }
    let input = SolanaSigningInput.with {
      $0.tokenTransferTransaction = tokenTransferMessage
      $0.recentBlockhash = recentBlockhash
      $0.privateKey = privateKeyData
    }
    let output: SolanaSigningOutput = AnySigner.sign(input: input, coin: .solana)
    return output.encoded
  }
  
  static func signCreateAndTransferToken(recipientMainAddress: String, tokenMintAddress: String, senderTokenAddress: String, privateKeyData: Data, recipientTokenAddress: String, amount: UInt64, recentBlockhash: String, tokenDecimals: UInt32) -> String {
    let createAndTransferTokenMessage = SolanaCreateAndTransferToken.with {
      $0.recipientMainAddress = recipientMainAddress
      $0.tokenMintAddress = tokenMintAddress
      $0.recipientTokenAddress = recipientTokenAddress
      $0.senderTokenAddress = senderTokenAddress
      $0.amount = amount
      $0.decimals = tokenDecimals
    }
    let input = SolanaSigningInput.with {
      $0.createAndTransferTokenTransaction = createAndTransferTokenMessage
      $0.recentBlockhash = recentBlockhash
      $0.privateKey = privateKeyData
    }

    let output: SolanaSigningOutput = AnySigner.sign(input: input, coin: .solana)
    return output.encoded
  }
  
  static func getMinimumBalanceForRentExemption(completion: @escaping (Int?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getMinimumBalanceForRentExemption) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let result = json["result"] as? Int {
           completion(result)
            return
          }
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }

  static func getRecentBlockhash(completion: @escaping (String?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getRecentBlockhash) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary,
             let valueJson = resultJson["value"] as? JSONDictionary,
             let blockHash = valueJson["blockhash"] as? String {
            completion(blockHash)
            return
          }
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
  static func getLamportsPerSignature(completion: @escaping (Int?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getRecentBlockhash) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary,
             let valueJson = resultJson["value"] as? JSONDictionary,
             let feeJson = valueJson["feeCalculator"] as? JSONDictionary,
             let lamportsPerSignature = feeJson["lamportsPerSignature"] as? Int {
            completion(lamportsPerSignature)
            return
          }
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
  static func getTokenAccountsByOwner(ownerAddress: String, tokenAddress: String, completion: @escaping (String?, String?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getTokenAccountsByOwner(ownerAddress: ownerAddress, tokenAddress: tokenAddress)) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary,
             let valueJsons = resultJson["value"] as? [JSONDictionary] {
            for value in valueJsons {
              if let pubKey = value["pubkey"] as? String {
                let account = value["account"] as? JSONDictionary
                let data = account?["data"] as? JSONDictionary
                let parsed = data?["parsed"] as? JSONDictionary
                let info = parsed?["info"] as? JSONDictionary
                let tokenAmount = info?["tokenAmount"] as? JSONDictionary
                
                if let amount = tokenAmount?["amount"] as? String {
                  completion(amount, pubKey)
                  return
                }
                
                completion(nil, pubKey)
                return
              }
            }
          }
        }
        completion(nil, nil)
      case .failure(let error):
        completion(nil, nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
  static func sendSignedTransaction(signedTransaction: String, completion: @escaping (String?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.sendTransaction(signedTransaction: signedTransaction)) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let signatureResult = json["result"] as? String {
            completion(signatureResult)
            return
          }
//          else if let error = json["error"] as? JSONDictionary {
//            let errorMsg = error["message"] as? String ?? "Error"
//            completion(nil)
//          }
          completion(nil)
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
  static func getTransactionStatus(signature: String, completion: @escaping (InternalTransactionState?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getSignatureStatuses(signature: signature)) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary {
            if let valueArray = resultJson["value"] as? [JSONDictionary] {
              var status: InternalTransactionState = valueArray.isEmpty ? .done : .pending
              valueArray.forEach { valueJson in
                if let statusString = valueJson["confirmationStatus"] as? String, statusString == "confirmed" || statusString == "finalized" {
                  status = .done
                }
              }
              completion(status)
              return
            }          }
        }
        completion(nil)
      case .failure(let error):
        print("[Solana error] \(error.localizedDescription)")
        completion(nil)
      }
    }
  }
  
  static func getBalance(address: String, completion: @escaping (BigInt?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getBalance(address: address)) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary {
            if let value = resultJson["value"] as? Int {
              completion(BigInt(value))
              return
            }
          }
        }
        completion(nil)
      case .failure(let error):
        print("[Solana error] \(error.localizedDescription)")
        completion(nil)
      }
    }
  }
  
  static func convertBase58Data(addressString: String) -> Data? {
    return Base58.decodeNoCheck(string: addressString)
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
  
  func importKeyPair(_ key: String) -> (String?, WalletCore.Account?, String?) {
    guard let pk = SolanaUtil.keyPairToPrivateKey(key) else {
      return (nil, nil, nil)
    }
    let newPassword = PasswordGenerator.generateRandom()
    let wallet = try? self.keyStore.import(privateKey: pk, name: "", password: newPassword, coin: .ethereum)
    if let unwrap = wallet {
      self.setPassword(newPassword, for: unwrap)
      let address = AnyAddress(publicKey: pk.getPublicKeyEd25519(), coin: .solana)
      self.keysDict[address.description] = unwrap.identifier
      let account = try! unwrap.getAccount(password: newPassword, coin: .ethereum)
      return (address.description, account, unwrap.identifier)
    }
    
    return (nil, nil, nil)
  }
  
  func importSoletString(_ key: String) -> (String?, WalletCore.Account?, String?) {
    guard let pk = SolanaUtil.soletStringToPrivateKey(key) else {
      return (nil, nil, nil)
    }
    
    let newPassword = PasswordGenerator.generateRandom()
    let wallet = try? self.keyStore.import(privateKey: pk, name: "", password: newPassword, coin: .ethereum)
    if let unwrap = wallet {
      self.setPassword(newPassword, for: unwrap)
      let address = AnyAddress(publicKey: pk.getPublicKeyEd25519(), coin: .solana)
      self.keysDict[address.description] = unwrap.identifier
      let account = try! unwrap.getAccount(password: newPassword, coin: .ethereum)
      return (address.description, account, unwrap.identifier)
    }
    
    return (nil, nil, nil)
  }
  
  func importSoletSeeds(_ seeds: String) -> (String?, WalletCore.Account?, String?) {
    guard let pk = SolanaUtil.soletSeedsToPrivateKey(seeds) else {
      return (nil, nil, nil)
    }
    
    let newPassword = PasswordGenerator.generateRandom()
    let wallet = try? self.keyStore.import(privateKey: pk, name: "", password: newPassword, coin: .ethereum)
    if let unwrap = wallet {
      self.setPassword(newPassword, for: unwrap)
      let address = AnyAddress(publicKey: pk.getPublicKeyEd25519(), coin: .solana)
      self.keysDict[address.description] = unwrap.identifier
      let account = try! unwrap.getAccount(password: newPassword, coin: .ethereum)
      return (address.description, account, unwrap.identifier)
    }
    
    return (nil, nil, nil)
  }
  
  func exportKeyPair(walletID: String) -> PrivateKey? {
    let filtered = self.keyStore.wallets.first { element in
      return element.identifier == walletID
    }
    
    guard let wallet = filtered, let password = self.getPassword(for: wallet), let data = try? self.keyStore.exportPrivateKey(wallet: wallet, password: password) else { return nil }
    
    let pk = PrivateKey(data: data)
    return pk
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
  
  static func exportKeyPair(privateKey: PrivateKey) -> String {
    let publicKey = privateKey.getPublicKeyEd25519()
    let privateKeyData = privateKey.data
    let publicKeyData = publicKey.data
    
    let data = privateKeyData + publicKeyData
    let keyPairString = Base58.encodeNoCheck(data: data)
    return keyPairString
  }
  
  static func isVaildSolanaAddress(_ address: String) -> Bool {
    return AnyAddress.isValid(string: address, coin: .solana)
  }
  
  func addWatchWallet(name: String, address: String) {
    let watch = Watch(coin: .solana, name: name, address: address, xpub: nil)
    do {
      try self.keyStore.watch([watch])
    } catch {
    }
  }
  
  func matchWatchWallet(_ address: String) -> Watch? {
    return self.keyStore.watches.first { element in
      return element.address == address
    }
  }
  
  func removeWatchWallet(_ address: String) {
    if let watch = self.matchWatchWallet(address) {
      do {
        try self.keyStore.removeWatch(watch)
      } catch {
      }
    }
  }
  
  func matchWallet(walletID: String) -> WalletCore.Wallet? {
    return self.keyStore.wallets.first { element in
      return element.identifier == walletID
    }
  }
  
  func removeWallet(walletID: String) {
    guard let wallet = self.matchWallet(walletID: walletID), let password = self.getPassword(for: wallet) else { return }
    do {
      _ = try self.keyStore.removeAccounts(wallet: wallet, coins: [.solana], password: password)
    } catch {
    }
  }
  
}
