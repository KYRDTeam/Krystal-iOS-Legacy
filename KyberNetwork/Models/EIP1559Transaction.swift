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
    let baseFeeBigInt = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let cancelGas = self.gasPriceForCancelTransaction()
    let maxGasFee = baseFeeBigInt + cancelGas
    return EIP1559Transaction(
      chainID: self.chainID,
      nonce: self.nonce,
      gasLimit: self.gasLimit,
      maxInclusionFeePerGas: cancelGas.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
      toAddress: self.toAddress,
      fromAddress: self.toAddress,
      data: "",
      value: "00"
    )
  }

  func toSpeedupTransaction(gasPrice: BigInt) -> EIP1559Transaction {
    let baseFeeBigInt = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let maxGasFee = baseFeeBigInt + gasPrice
    return EIP1559Transaction(
      chainID: self.chainID,
      nonce: self.nonce,
      gasLimit: self.gasLimit,
      maxInclusionFeePerGas: gasPrice.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
      toAddress: self.toAddress,
      fromAddress: self.fromAddress,
      data: self.data,
      value: self.value
    )
  }
  
  func toSpeedupTransaction(gasLimit: String, priorityFee: String, maxGasFee: String) -> EIP1559Transaction {
    let gasLimitBigInt = BigInt(gasLimit) ?? BigInt(0)
    let priorityFeeBigInt = priorityFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
    let maxGasFeeBigInt = maxGasFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
    
    return EIP1559Transaction(
      chainID: self.chainID,
      nonce: self.nonce,
      gasLimit: gasLimitBigInt.hexEncoded.hexSigned2Complement,
      maxInclusionFeePerGas: priorityFeeBigInt.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasFeeBigInt.hexEncoded.hexSigned2Complement,
      toAddress: self.toAddress,
      fromAddress: self.fromAddress,
      data: self.data,
      value: self.value
    )
  }
  
  func toCancelTransaction(gasLimit: String, priorityFee: String, maxGasFee: String) -> EIP1559Transaction {
    let gasLimitBigInt = BigInt(gasLimit) ?? BigInt(0)
    let priorityFeeBigInt = priorityFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
    let maxGasFeeBigInt = maxGasFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
    return EIP1559Transaction(
      chainID: self.chainID,
      nonce: self.nonce,
      gasLimit: gasLimitBigInt.hexEncoded.hexSigned2Complement,
      maxInclusionFeePerGas: priorityFeeBigInt.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasFeeBigInt.hexEncoded.hexSigned2Complement,
      toAddress: self.fromAddress,
      fromAddress: self.fromAddress,
      data: "",
      value: "00"
    )
  }

  fileprivate func gasPriceForCancelTransaction() -> BigInt {
    guard
      let currentGasPrice = BigInt(self.maxInclusionFeePerGas.drop0x, radix: 16)
    else
    {
      return KNGasConfiguration.gasPriceMax
    }
    let gasPrice = currentGasPrice * BigInt(1.2 * pow(10.0, 18.0)) / BigInt(10).power(18)
    return gasPrice
  }
  
  func transactionGasPrice() -> BigInt? {
    return BigInt(self.maxInclusionFeePerGas.drop0x, radix: 16)
  }
}


