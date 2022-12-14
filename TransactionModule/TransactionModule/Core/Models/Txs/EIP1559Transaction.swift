//
//  EIP1559Transaction.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import WalletCore

public struct EIP1559Transaction: Codable {
    public let chainID: String
    public let nonce: String
    public let gasLimit: String
    public let maxInclusionFeePerGas: String
    public let maxGasFee: String
    public let toAddress: String
    public let fromAddress: String
    public let data: String
    public let value: String
    public let reservedGasLimit: String
    
    public init(chainID: String, nonce: String, gasLimit: String, maxInclusionFeePerGas: String, maxGasFee: String, toAddress: String, fromAddress: String, data: String, value: String, reservedGasLimit: String) {
        self.chainID = chainID
        self.nonce = nonce
        self.gasLimit = gasLimit
        self.maxInclusionFeePerGas = maxInclusionFeePerGas
        self.maxGasFee = maxGasFee
        self.toAddress = toAddress
        self.fromAddress = fromAddress
        self.data = data
        self.value = value
        self.reservedGasLimit = reservedGasLimit
    }
    
    public func signContractGenericWithPK(_ key: Data) -> Data {
        let input = EthereumSigningInput.with {
            $0.chainID = Data(hex: self.chainID)
            $0.nonce = Data(hex: self.nonce)
            $0.txMode = .enveloped
            $0.gasLimit = Data(hexString: self.gasLimit)!
            $0.maxInclusionFeePerGas = Data(hexString: self.maxInclusionFeePerGas)!
            $0.maxFeePerGas = Data(hexString: self.maxGasFee)!
            $0.toAddress = self.toAddress
            $0.privateKey = key
            $0.transaction = EthereumTransaction.with {
                $0.contractGeneric = EthereumTransaction.ContractGeneric.with {
                    if !value.isEmpty {
                        $0.amount = Data(hexString: self.value)!
                    }
                    $0.data = Data(hexString: self.data)!
                }
            }
        }
        let output: EthereumSigningOutput = AnySigner.sign(input: input, coin: .ethereum)
        return output.encoded
    }
    
    public func signTransferWithPK(_ key: Data) -> Data {
        let input = EthereumSigningInput.with {
            $0.chainID = Data(hex: self.chainID)
            $0.nonce = Data(hex: self.nonce)
            $0.txMode = .enveloped
            $0.gasLimit = Data(hexString: self.gasLimit)!
            $0.maxInclusionFeePerGas = Data(hexString: self.maxInclusionFeePerGas)!
            $0.maxFeePerGas = Data(hexString: self.maxGasFee)!
            $0.toAddress = self.toAddress
            $0.privateKey = key
            $0.transaction = EthereumTransaction.with {
                $0.transfer = EthereumTransaction.Transfer.with {
                    $0.amount = Data(hexString: self.value)!
                }
            }
        }
        let output: EthereumSigningOutput = AnySigner.sign(input: input, coin: .ethereum)
        return output.encoded
    }
    
}
