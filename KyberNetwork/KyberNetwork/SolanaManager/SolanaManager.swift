//
//  SolanaManager.swift
//  KyberNetwork
//
//  Created by Com1 on 13/04/2022.
//

import WalletCore

private let NEW_PASSWORD = PasswordGenerator.generateRandom()
private let SOLANA_DERIVATION_PATH = "m/44'/501'/0'/0'"

class SolanaManager: NSObject {
  let keyStore: KeyStore
  init(keyStore: KeyStore) {
    self.keyStore = keyStore
  }
  
  func importWallet(privateKey: String, name: String) -> WalletCore.Wallet? {
    do {
      let wallet = try self.keyStore.import(privateKey: PrivateKey(data: Base58.decodeNoCheck(string: privateKey)!)!, name: name, password: NEW_PASSWORD, coin: CoinType.solana)
      
      return wallet
      
    } catch {
      print("Import wallet error")
      return nil
    }
  }
  
  func exportWalletPrivateKey(wallet: WalletCore.Wallet) -> String? {
    do {
      let keyData = try self.keyStore.exportPrivateKey(wallet: wallet, password: NEW_PASSWORD)
      let privateKey = Base58.encodeNoCheck(data: keyData)
      return privateKey
    } catch {
      print("Export wallet error")
      return nil
    }
  }
  
  func importWallet(mnemonic: String, name: String) -> WalletCore.Wallet? {
    do {
      let wallet = try self.keyStore.import(mnemonic: mnemonic, name: name, encryptPassword: NEW_PASSWORD, coins: [.solana])
      
      return wallet
      
    } catch {
      print("Import wallet error")
      return nil
    }
  }
  
  func exportWalletMnemonic(wallet: WalletCore.Wallet) -> String? {
    do {
      let mnemonic = try self.keyStore.exportMnemonic(wallet: wallet, password: NEW_PASSWORD)
      return mnemonic
    } catch {
      print("Export wallet error")
      return nil
    }
  }
  
  func generatePrivateKey(mnemonic: String) -> PrivateKey? {
    let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "")
    let solanaPK = hdWallet?.getKey(coin: .solana, derivationPath: SOLANA_DERIVATION_PATH)
    return solanaPK
  }
  
  func getPrivateKey(keyPair: String) -> PrivateKey? {
    guard let data = Base58.decodeNoCheck(string: keyPair) else {
      return nil
    }
    let solPrivateKey = PrivateKey(data: data.subdata(in: Range(0...31)))
    return solPrivateKey
  }
  
  func generateKeyPair(pivateKey: PrivateKey) -> String {
    let solPublicKey = pivateKey.getPublicKeyEd25519()
    var resultData = pivateKey.data
    let publicKeyData = solPublicKey.data
    resultData.append(publicKeyData)
    let convertedKeyPair = Base58.encodeNoCheck(data: resultData)
    return convertedKeyPair
  }
  
  func generateAddress(privateKey: PrivateKey) -> String {
    let address = AnyAddress(publicKey: (privateKey.getPublicKeyEd25519()), coin: .solana)
    return address.description
  }
}
