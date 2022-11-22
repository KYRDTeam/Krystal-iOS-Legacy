//
//  EIP1559Transaction.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/10/2021.
//

import Foundation
import WalletCore
import BigInt

extension EIP1559Transaction: Codable {

  func toSpeedupTransaction(gasPrice: BigInt) -> EIP1559Transaction {
    let baseFeeBigInt = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let maxGasFee = baseFeeBigInt + gasPrice
    return EIP1559Transaction(
      chainID: self.chainID,
      nonce: self.nonce,
      gasLimit: self.reservedGasLimit,
      maxInclusionFeePerGas: gasPrice.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
      toAddress: self.toAddress,
      fromAddress: self.fromAddress,
      data: self.data,
      value: self.value,
      reservedGasLimit: self.reservedGasLimit
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
      value: self.value,
      reservedGasLimit: self.reservedGasLimit
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
      value: "00",
      reservedGasLimit: self.reservedGasLimit
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
    return BigInt(self.maxGasFee.drop0x, radix: 16)
  }
}

extension EIP1559Transaction: GasLimitRequestable {
  func createGasLimitRequest() -> KNEstimateGasLimitRequest {
    let request = KNEstimateGasLimitRequest(
      from: self.fromAddress,
      to: self.toAddress,
      value: BigInt(self.value.drop0x, radix: 16) ?? BigInt(0),
      data: Data(hexString: self.data) ?? Data(),
      gasPrice: BigInt(self.maxGasFee.drop0x, radix: 16) ?? BigInt(0)
    )
    return request
  }
}


