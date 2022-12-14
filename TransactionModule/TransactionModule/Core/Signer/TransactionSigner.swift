//
//  TransactionSigner.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import BigInt
import CryptoSwift
import TrustCore

public protocol Signer {
    func hash(transaction: LegacyTransaction) -> Data
    func values(transaction: LegacyTransaction, signature: Data) -> (r: BigInt, s: BigInt, v: BigInt)
}

public struct EIP155Signer: Signer {
    public let chainId: BigInt
    
    public init(chainId: BigInt) {
        self.chainId = chainId
    }
    
    public func hash(transaction: LegacyTransaction) -> Data {
        return rlpHash([
            transaction.nonce,
            transaction.gasPrice,
            transaction.gasLimit,
            transaction.to.map { Data(hexString: $0) ?? Data() } ?? Data(),
            transaction.value,
            transaction.data,
            transaction.chainID, 0, 0,
        ] as [Any])!
    }
    
    public func values(transaction: LegacyTransaction, signature: Data) -> (r: BigInt, s: BigInt, v: BigInt) {
        let (r, s, v) = HomesteadSigner().values(transaction: transaction, signature: signature)
        let newV: BigInt
        if chainId != 0 {
            newV = BigInt(signature[64]) + 35 + chainId + chainId
        } else {
            newV = v
        }
        return (r, s, newV)
    }
}

public struct HomesteadSigner: Signer {
    public func hash(transaction: LegacyTransaction) -> Data {
        return rlpHash([
            transaction.nonce,
            transaction.gasPrice,
            transaction.gasLimit,
            transaction.to?.data ?? Data(),
            transaction.value,
            transaction.data,
        ])!
    }
    
    public func values(transaction: LegacyTransaction, signature: Data) -> (r: BigInt, s: BigInt, v: BigInt) {
        precondition(signature.count == 65, "Wrong size for signature")
        let r = BigInt(sign: .plus, magnitude: BigUInt(Data(bytes: signature[..<32])))
        let s = BigInt(sign: .plus, magnitude: BigUInt(Data(bytes: signature[32..<64])))
        let v = BigInt(sign: .plus, magnitude: BigUInt(Data(bytes: [signature[64] + 27])))
        return (r, s, v)
    }
}

public func rlpHash(_ element: Any) -> Data? {
    let sha3 = SHA3(variant: .keccak256)
    guard let data = RLP.encode(element) else {
        return nil
    }
    return Data(bytes: sha3.calculate(for: data.bytes))
}
