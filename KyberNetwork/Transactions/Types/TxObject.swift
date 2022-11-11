//
//  TxObject.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import BigInt
import TrustCore
import TrustKeystore
import TransactionModule

struct TxObject: Codable {
    var nonce: String
    let from, to, data, value: String
    let gasPrice, gasLimit: String
}

extension TxObject {
  func convertToSignTransaction(address: String, advancedGasPrice: String? = nil, advancedGasLimit: String? = nil, advancedNonce: String? = nil) -> SignTransaction? {
    guard
      let value = BigInt(self.value.drop0x, radix: 16),
      var gasPrice = BigInt(self.gasPrice.drop0x, radix: 16),
      var gasLimit = BigInt(self.gasLimit.drop0x, radix: 16),
      var nonce = Int(self.nonce.drop0x, radix: 16)
    else
    {
      return nil
    }
    if let unwrap = advancedGasPrice, let value = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      gasPrice = value
    }
    
    if let unwrap = advancedGasLimit, let value = BigInt(unwrap) {
      gasLimit = value
    }
    
    if let unwrap = advancedNonce, let value = Int(unwrap) {
      nonce = value
    }
    return SignTransaction(
      value: value,
      address: address,
      to: self.to,
      nonce: nonce,
      data: Data(hex: self.data.drop0x),
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  
  func newTxObjectWithNonce(nonce: Int) -> TxObject {
    let nonceString = BigInt(nonce).hexEncoded
    return TxObject(nonce: nonceString, from: self.from, to: self.to, data: self.data, value: self.value, gasPrice: self.gasPrice, gasLimit: self.gasLimit)
  }
  
  func newTxObjectWithGasPrice(gasPrice: BigInt) -> TxObject {
    let gasPriceString = gasPrice.hexEncoded
    return TxObject(nonce: self.nonce, from: self.from, to: self.to, data: self.data, value: self.value, gasPrice: gasPriceString, gasLimit: self.gasLimit)
  }

  func convertToEIP1559Transaction(advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxGas: String?, advancedNonce: String?) -> EIP1559Transaction? {
    guard let baseFeeBigInt = KNGasCoordinator.shared.baseFee else { return nil }
    let gasLimitDefault = BigInt(self.gasLimit.drop0x, radix: 16) ?? BigInt(0)
    let gasPrice = BigInt(self.gasPrice.drop0x, radix: 16) ?? BigInt(0)
    let priorityFeeBigIntDefault = gasPrice - baseFeeBigInt
    let maxGasFeeDefault = gasPrice
    let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
    var nonce = self.nonce.hexSigned2Complement
    if let customNonceString = advancedNonce, let nonceInt = Int(customNonceString) {
      let nonceBigInt = BigInt(nonceInt)
      nonce = nonceBigInt.hexEncoded.hexSigned2Complement
    }
    if let advancedGasStr = advancedGasLimit,
       let gasLimit = BigInt(advancedGasStr),
       let priorityFeeString = advancedPriorityFee,
       let priorityFee = BigInt(priorityFeeString),
       let maxGasFeeString = advancedMaxGas,
       let maxGasFee = BigInt(maxGasFeeString) {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFee.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
        toAddress: self.to,
        fromAddress: self.from,
        data: self.data,
        value: self.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
        )
    } else {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFeeDefault.hexEncoded.hexSigned2Complement,
        toAddress: self.to,
        fromAddress: self.from,
        data: self.data,
        value: self.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    }
  }
    
  func convertToSignTransaction(address: String, nonce: Int, settings: UserSettings) -> SignTransaction? {
    guard !KNGeneralProvider.shared.isUseEIP1559 else {
      return nil
    }
    
    guard
      let value = BigInt(value.drop0x, radix: 16),
      let gasLimitTx = BigInt(gasLimit.drop0x, radix: 16)
    else
    {
      return nil
    }
    let gasPrice = settings.1?.maxFee ?? settings.0.gasPriceType.getGasValue()
    let gasLimit = settings.1?.gasLimit ?? gasLimitTx
    let txNonce = settings.1?.nonce ?? nonce
    
    return SignTransaction(
      value: value,
      address: address,
      to: self.to,
      nonce: txNonce,
      data: Data(hex: self.data.drop0x),
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  func convertToEIP1559Transaction(address: String, nonce: Int, settings: UserSettings) -> EIP1559Transaction? {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return nil
    }
    guard
      let value = BigInt(value.drop0x, radix: 16),
      let gasLimitTx = BigInt(gasLimit.drop0x, radix: 16)
    else
    {
      return nil
    }
    guard let baseFeeBigInt = KNGasCoordinator.shared.baseFee else { return nil }

    let txNonce = settings.1?.nonce ?? nonce
    let maxGas = settings.1?.maxFee ?? settings.0.gasPriceType.getGasValue()
    let priorityFee = settings.1?.maxPriorityFee ?? settings.0.gasPriceType.getPriorityFeeValue()
    let gasLimit = settings.1?.gasLimit ?? gasLimitTx
    let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
    let nonceHex = BigInt(txNonce).hexEncoded
    
    let gasPrice = BigInt(self.gasPrice.drop0x, radix: 16) ?? BigInt(0)
    let priorityFeeBigIntDefault = maxGas - baseFeeBigInt
    return EIP1559Transaction(
      chainID: chainID.hexSigned2Complement,
      nonce: nonceHex,
      gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
      maxInclusionFeePerGas: priorityFee?.hexEncoded.hexSigned2Complement ?? priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGas.hexEncoded.hexSigned2Complement,
      toAddress: self.to,
      fromAddress: self.from,
      data: self.data,
      value: self.value.drop0x.hexSigned2Complement,
      reservedGasLimit: gasLimit.hexEncoded.hexSigned2Complement
    )
  }
}
