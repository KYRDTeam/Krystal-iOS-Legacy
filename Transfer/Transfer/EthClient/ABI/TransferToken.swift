//
//  TransferParam.swift
//  Transfer
//
//  Created by Tung Nguyen on 14/03/2023.
//

import Foundation
import web3
import BigInt

struct TransferToken: ABIFunction {
    static var name: String = "transfer"
    var contract: EthereumAddress
    var from: EthereumAddress?
    var gasPrice: BigUInt?
    var gasLimit: BigUInt?
    
    var walletAddress: EthereumAddress
    var token: EthereumAddress
    var to: EthereumAddress
    var amount: BigUInt
    var data: Data
    
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(walletAddress)
        try encoder.encode(token)
        try encoder.encode(to)
        try encoder.encode(amount)
        try encoder.encode(data)
    }
    
}
