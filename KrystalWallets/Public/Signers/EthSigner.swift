//
//  EthSigner.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 07/06/2022.
//

import Foundation
import WalletCore
import CryptoSwift

public class EthSigner: KSignerProtocol {
  
  let walletManager = WalletManager.shared
  
  public init() {}
    
    public func signMessage(address: KAddress, message: String, addPrefix: Bool) throws -> Data {
        return try signMessageHash(address: address, data: Data(message.utf8), addPrefix: addPrefix)
    }
    
    public func signEip712Data(address: KAddress, data: Data) throws -> Data {
        guard let wallet = walletManager.wallet(forAddress: address) else {
          throw SigningError.addressNotFound
        }
        let privateKey = try walletManager.getPrivateKey(wallet: wallet, forAddressType: .evm)
        var signed = privateKey.sign(digest: data, curve: .secp256k1)!
        signed[64] += 27
        return signed
    }
    
  public func signMessageHash(address: KAddress, data: Data, addPrefix: Bool) throws -> Data {
    guard let wallet = walletManager.wallet(forAddress: address) else {
      throw SigningError.addressNotFound
    }
    let message = (addPrefix ? ethereumMessage(for: data) : data).sha3(.keccak256)
    let privateKey = try walletManager.getPrivateKey(wallet: wallet, forAddressType: .evm)
    var signed = privateKey.sign(digest: message, curve: .secp256k1)!
    signed[64] += 27
    return signed
  }
  
  public func signTransaction(address: KAddress, hash: Data) throws -> Data {
    guard let wallet = walletManager.wallet(forAddress: address) else {
      throw SigningError.addressNotFound
    }
    let privateKey = try walletManager.getPrivateKey(wallet: wallet, forAddressType: .evm)
    return privateKey.sign(digest: hash, curve: .secp256k1)!
  }

  private func ethereumMessage(for data: Data) -> Data {
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    return prefix + data
  }
  
}
