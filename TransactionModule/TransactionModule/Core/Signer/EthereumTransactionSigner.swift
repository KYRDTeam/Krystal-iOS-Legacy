//
//  EthereumTransactionSigner.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import KrystalWallets
import Result
import BigInt
import TrustCore

public class EthereumTransactionSigner {
    
    public init() {}
    
    public func signTransaction(address: KAddress, transaction: LegacyTransaction) -> Result<Data, AnyError> {
        do {
            let signer: Signer
            if transaction.chainID == 0 {
                signer = HomesteadSigner()
            } else {
                signer = EIP155Signer(chainId: BigInt(transaction.chainID))
            }
            
            let hash = signer.hash(transaction: transaction)
            let signature = try EthSigner().signTransaction(address: address, hash: hash)
            let (r, s, v) = signer.values(transaction: transaction, signature: signature)
            let data = RLP.encode([
                transaction.nonce,
                transaction.gasPrice,
                transaction.gasLimit,
                transaction.to.map { Data(hexString: $0) ?? Data() } ?? Data(),
                transaction.value,
                transaction.data,
                v, r, s,
            ])!
            return .success(data)
        } catch {
            return .failure(AnyError(error))
        }
    }
    
}
