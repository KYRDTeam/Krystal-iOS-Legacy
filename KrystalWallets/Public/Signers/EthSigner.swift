//
//  EthSigner.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 07/06/2022.
//

import Foundation
import WalletCore

public class EthSigner: KSignerProtocol {
  
  let walletManager = WalletManager.shared
  
  public init() {}
  
  public func signHash(address: KAddress, hash: Data) throws -> Data {
    guard let wallet = walletManager.wallet(forAddress: address) else {
      throw SigningError.addressNotFound
    }
    let privateKey = try walletManager.privateKey(wallet: wallet, forAddressType: .evm)
    return privateKey.sign(digest: hash, curve: .secp256k1)!
  }
  
  public func signMessage(address: KAddress, data: Data, addPrefix: Bool) throws -> Data {
    guard let wallet = walletManager.wallet(forAddress: address) else {
      throw SigningError.addressNotFound
    }
    let message = addPrefix ? Hash.keccak256(data: ethereumMessage(for: data)) : data
    let privateKey = try walletManager.privateKey(wallet: wallet, forAddressType: .evm)
    var signed = privateKey.sign(digest: message, curve: .secp256k1)!
    signed[64] += 27
    return signed
  }
  
  private func ethereumMessage(for data: Data) -> Data {
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    return prefix + data
  }
  
}
