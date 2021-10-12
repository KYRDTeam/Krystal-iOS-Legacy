//
//  EIP1559Transaction.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/10/2021.
//

import Foundation
import WalletCore
import BigInt

struct EIP1559Transaction: Codable {
  let chainID: String
  let nonce: String
  let gasLimit: String
  let maxInclusionFeePerGas: String
  let maxGasFee: String
  let toAddress: String
  let fromAddress: String
  let data: String
  let value: String

  func signContractGenericWithPK(_ key: Data) -> Data {
    let input = EthereumSigningInput.with {
      $0.chainID = Data(hexString: self.chainID)!
      $0.nonce = Data(hexString: self.nonce)!
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

  func signTransferWithPK(_ key: Data) -> Data {
    let input = EthereumSigningInput.with {
      $0.chainID = Data(hexString: self.chainID)!
      $0.nonce = Data(hexString: self.nonce)!
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
  
  func toCancelTransaction() -> EIP1559Transaction {
    let cancelGas = self.gasPriceForCancelTransaction()
    return EIP1559Transaction(
      chainID: self.chainID,
      nonce: self.nonce,
      gasLimit: self.gasLimit,
      maxInclusionFeePerGas: self.maxInclusionFeePerGas,
      maxGasFee: cancelGas.hexEncoded.hexSigned2Complement,
      toAddress: self.toAddress,
      fromAddress: self.fromAddress,
      data: self.data,
      value: self.value
    )
  }
  
  func toSpeedupTransaction(gasPrice: BigInt) -> EIP1559Transaction {
    return EIP1559Transaction(
      chainID: self.chainID,
      nonce: self.nonce,
      gasLimit: self.gasLimit,
      maxInclusionFeePerGas: self.maxInclusionFeePerGas,
      maxGasFee: gasPrice.hexEncoded.hexSigned2Complement,
      toAddress: self.toAddress,
      fromAddress: self.fromAddress,
      data: self.data,
      value: self.value
    )
  }
  
  fileprivate func gasPriceForCancelTransaction() -> BigInt {
    guard
      let currentGasPrice = BigInt(self.maxGasFee.drop0x, radix: 16)
    else
    {
      return KNGasConfiguration.gasPriceMax
    }
    let gasPrice = max(currentGasPrice * BigInt(1.2 * pow(10.0, 18.0)) / BigInt(10).power(18), KNGasConfiguration.gasPriceMax)
    return gasPrice
  }
  
  
}


