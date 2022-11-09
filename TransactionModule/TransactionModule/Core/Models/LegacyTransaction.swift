//
//  LegacyTransaction.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import BigInt

public struct LegacyTransaction {
    public let value: BigInt
    public let address: String
    public let to: String?
    public let nonce: Int
    public let data: Data
    public let gasPrice: BigInt
    public let gasLimit: BigInt
    public let chainID: Int
    
    public init(value: BigInt, address: String, to: String?, nonce: Int, data: Data, gasPrice: BigInt, gasLimit: BigInt, chainID: Int) {
        self.value = value
        self.address = address
        self.to = to
        self.nonce = nonce
        self.data = data
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.chainID = chainID
    }
}
