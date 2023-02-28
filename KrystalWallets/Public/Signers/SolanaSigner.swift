//
//  SolanaSigner.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 09/06/2022.
//

import Foundation
import WalletCore

public class SolanaSigner: KSignerProtocol {
  let walletManager = WalletManager.shared
  
  public init() {}
  
  public func signTransaction(address: KAddress, hash: Data) throws -> Data {
    throw SigningError.cannotSignMessage
  }
    
    public func signMessage(address: KAddress, message: String, addPrefix: Bool) throws -> Data {
        let decoded = Base58.decodeNoCheck(string: message) ?? Data()
        return try signMessageHash(address: address, data: decoded, addPrefix: addPrefix)
    }
  
  public func signMessageHash(address: KAddress, data: Data, addPrefix: Bool) throws -> Data {
      guard let wallet = walletManager.wallet(forAddress: address) else {
          throw SigningError.addressNotFound
      }
      let privateKey = try walletManager.getPrivateKey(wallet: wallet, forAddressType: .solana)
      guard let signature = privateKey.sign(digest: data, curve: .ed25519) else {
          return Data()
      }
      return signature
  }
  
  public func signTransferTransaction(address: KAddress, recipient: String, value: UInt64, recentBlockhash: String) throws -> String {
    guard let wallet = walletManager.wallet(forAddress: address) else {
      throw SigningError.addressNotFound
    }
    let privateKey = try walletManager.getPrivateKey(wallet: wallet, forAddressType: .solana)
    
    let transferMessage = SolanaTransfer.with {
      $0.recipient = recipient
      $0.value = value
    }
    let input = SolanaSigningInput.with {
      $0.transferTransaction = transferMessage
      $0.recentBlockhash = recentBlockhash
      $0.privateKey = privateKey.data
    }

    let output: SolanaSigningOutput = AnySigner.sign(input: input, coin: .solana)
    return output.encoded
  }
  
  public func signTokenTransferTransaction(address: KAddress, tokenMintAddress: String, senderTokenAddress: String, recipientTokenAddress: String, amount: UInt64, recentBlockhash: String, tokenDecimals: UInt32) throws -> String {
    guard let wallet = walletManager.wallet(forAddress: address) else {
      throw SigningError.addressNotFound
    }
    let privateKey = try walletManager.getPrivateKey(wallet: wallet, forAddressType: .solana)
    
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
      $0.privateKey = privateKey.data
    }
    let output: SolanaSigningOutput = AnySigner.sign(input: input, coin: .solana)
    return output.encoded
  }
  
  public func signCreateAndTransferToken(address: KAddress, recipientMainAddress: String, tokenMintAddress: String, recipientTokenAddress: String, amount: UInt64, recentBlockhash: String, tokenDecimals: UInt32) throws -> String {
    guard let wallet = walletManager.wallet(forAddress: address) else {
      throw SigningError.addressNotFound
    }
    let privateKey = try walletManager.getPrivateKey(wallet: wallet, forAddressType: .solana)
    
    let createAndTransferTokenMessage = SolanaCreateAndTransferToken.with {
      $0.recipientMainAddress = recipientMainAddress
      $0.tokenMintAddress = tokenMintAddress
      $0.recipientTokenAddress = recipientTokenAddress
      $0.senderTokenAddress = address.addressString
      $0.amount = amount
      $0.decimals = tokenDecimals
    }
    let input = SolanaSigningInput.with {
      $0.createAndTransferTokenTransaction = createAndTransferTokenMessage
      $0.recentBlockhash = recentBlockhash
      $0.privateKey = privateKey.data
    }

    let output: SolanaSigningOutput = AnySigner.sign(input: input, coin: .solana)
    return output.encoded
  }
  
  public func generateTokenAccountAddress(receiptWalletAddress: String, tokenMintAddress: String) -> String {
    return SolanaAddress(string: receiptWalletAddress)?.defaultTokenAddress(tokenMintAddress: tokenMintAddress) ?? ""
  }
  
}
