//
//  TransactionFactory.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import BigInt
import TrustCore
import TrustKeystore

class TransactionFactory {
  static func buildEIP1559Transaction(from: String, to: String, nonce: Int, data: Data, value: BigInt = BigInt.zero, setting: ConfirmAdvancedSetting) -> EIP1559Transaction {
    var gasLimitBigInt = BigInt(setting.gasLimit)
    if let unwrap = setting.advancedGasLimit {
      gasLimitBigInt = BigInt(unwrap)
    }

    var maxGasBigInt = BigInt(setting.gasPrice)
    if let unwrap = setting.avancedMaxFee {
      maxGasBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }

    var priorityFeeBigInt = (maxGasBigInt ?? BigInt.zero) - (KNGasCoordinator.shared.baseFee ?? BigInt.zero)
    if let unwrap = setting.advancedPriorityFee {
      priorityFeeBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt.zero
    }

    return EIP1559Transaction(
      chainID: BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded.hexSigned2Complement,
      nonce: BigInt(nonce).hexEncoded.hexSigned2Complement,
      gasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      maxInclusionFeePerGas: priorityFeeBigInt.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      toAddress: to,
      fromAddress: from,
      data: data.hexString.add0x,
      value: value.hexEncoded.hexSigned2Complement,
      reservedGasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x")
  }
  
  static func buildLegacyTransaction(account: Account, to: String, nonce: Int, data: Data, value: BigInt = BigInt.zero, setting: ConfirmAdvancedSetting) -> SignTransaction {
    var gasLimitBigInt = BigInt(setting.gasLimit)
    if let unwrap = setting.advancedGasLimit {
      gasLimitBigInt = BigInt(unwrap)
    }

    var maxGasBigInt = BigInt(setting.gasPrice)
    if let unwrap = setting.avancedMaxFee {
      maxGasBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }

    return SignTransaction(
      value: value,
      account: account,
      to: to,
      nonce: nonce,
      data: data,
      gasPrice: maxGasBigInt ?? BigInt.zero,
      gasLimit: gasLimitBigInt ?? BigInt.zero,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  
  static func buildLegacyTransaction(address: String, to: String, nonce: Int, data: Data, value: BigInt = BigInt.zero, setting: ConfirmAdvancedSetting) -> SignTransaction {
    var gasLimitBigInt = BigInt(setting.gasLimit)
    if let unwrap = setting.advancedGasLimit {
      gasLimitBigInt = BigInt(unwrap)
    }

    var maxGasBigInt = BigInt(setting.gasPrice)
    if let unwrap = setting.avancedMaxFee {
      maxGasBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }

    return SignTransaction(
      value: value,
      address: address,
      to: to,
      nonce: nonce,
      data: data,
      gasPrice: maxGasBigInt ?? BigInt.zero,
      gasLimit: gasLimitBigInt ?? BigInt.zero,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  
  static func buildLegaryTransaction(txObject: TxObject, account: Account, setting: ConfirmAdvancedSetting) -> SignTransaction {
    var gasPrice = BigInt(txObject.gasPrice.drop0x, radix: 16)
    var gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16)
    var nonce = Int(txObject.nonce.drop0x, radix: 16)
    let value = BigInt(txObject.value.drop0x, radix: 16)
    if let value = BigInt(setting.gasPrice) {
      gasPrice = value
    }
    
    if let unwrap = setting.advancedGasLimit, let value = BigInt(unwrap) {
      gasLimit = value
    }
    
    if let value = setting.advancedNonce {
      nonce = value
    }

    return SignTransaction(
      value: value ?? BigInt.zero,
      account: account,
      to: txObject.to,
      nonce: nonce ?? 0,
      data: Data(hex: txObject.data.drop0x),
      gasPrice: gasPrice ?? BigInt.zero,
      gasLimit: gasLimit ?? BigInt.zero,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  
  static func buildLegacyTransaction(txObject: TxObject, address: String, setting: ConfirmAdvancedSetting) -> SignTransaction {
    var gasPrice = BigInt(txObject.gasPrice.drop0x, radix: 16)
    var gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16)
    var nonce = Int(txObject.nonce.drop0x, radix: 16)
    let value = BigInt(txObject.value.drop0x, radix: 16)
    if let value = BigInt(setting.gasPrice) {
      gasPrice = value
    }
    
    if let unwrap = setting.advancedGasLimit, let value = BigInt(unwrap) {
      gasLimit = value
    }
    
    if let value = setting.advancedNonce {
      nonce = value
    }

    return SignTransaction(
      value: value ?? BigInt.zero,
      address: address,
      to: txObject.to,
      nonce: nonce ?? 0,
      data: Data(hex: txObject.data.drop0x),
      gasPrice: gasPrice ?? BigInt.zero,
      gasLimit: gasLimit ?? BigInt.zero,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  
  static func buildEIP1559Transaction(txObject: TxObject, setting: ConfirmAdvancedSetting) -> EIP1559Transaction {
    let baseFeeBigInt = KNGasCoordinator.shared.baseFee ?? BigInt.zero
    let gasLimitDefault = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? BigInt.zero
    let gasPrice = BigInt(setting.gasPrice) ?? BigInt.zero
    let priorityFeeBigIntDefault = KNGasCoordinator.shared.standardPriorityFee ?? BigInt(0)
    let maxGasFeeDefault = gasPrice
    let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
    var nonce = txObject.nonce.hexSigned2Complement
    if let nonceInt = setting.advancedNonce {
      let nonceBigInt = BigInt(nonceInt)
      nonce = nonceBigInt.hexEncoded.hexSigned2Complement
    }
    
    if let advancedGasStr = setting.advancedGasLimit,
       let gasLimit = BigInt(advancedGasStr),
       let priorityFeeString = setting.advancedPriorityFee,
       let priorityFee = priorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit),
       let maxGasFeeString = setting.avancedMaxFee,
       let maxGasFee = maxGasFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFee.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
        toAddress: txObject.to,
        fromAddress: txObject.from,
        data: txObject.data,
        value: txObject.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    } else {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFeeDefault.hexEncoded.hexSigned2Complement,
        toAddress: txObject.to,
        fromAddress: txObject.from,
        data: txObject.data,
        value: txObject.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    }
    
  }
}
