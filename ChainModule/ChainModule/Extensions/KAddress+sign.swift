//
//  KAddress+sign.swift
//  ChainModule
//
//  Created by Tung Nguyen on 14/03/2023.
//

import Foundation
import web3
import KrystalWallets

extension KAddress: EthereumAccountProtocol {
    
    public var address: web3.EthereumAddress {
        return .init(addressString)
    }
    
    public func sign(data: Data) throws -> Data {
        return try EthSigner().signMessageHash(address: self, data: data, addPrefix: false)
    }
    
    public func sign(hash: String) throws -> Data {
        return try EthSigner().signMessage(address: self, message: hash, addPrefix: false)
    }
    
    public func sign(hex: String) throws -> Data {
        return try EthSigner().signMessageHash(address: self, data: Data(hex: hex), addPrefix: false)
    }
    
    public func sign(message: Data) throws -> Data {
        return try EthSigner().signMessageHash(address: self, data: message, addPrefix: true)
    }
    
    public func sign(message: String) throws -> Data {
        return try sign(message: message.data(using: .utf8) ?? Data())
    }
    
    public func sign(transaction: web3.EthereumTransaction) throws -> web3.SignedTransaction {
        guard let raw = transaction.raw else {
            throw SigningError.cannotSignTx
        }
        
        guard let signature = try? sign(data: raw) else {
            throw SigningError.cannotSignTx
        }
        
        let r = signature.subdata(in: 0 ..< 32)
        let s = signature.subdata(in: 32 ..< 64)
        
        var v = Int(signature[64])
        if v < 37 {
            v += (transaction.chainId ?? -1) * 2 + 35
        }
        
        return SignedTransaction(transaction: transaction, v: v, r: r, s: s)
    }
    
}
