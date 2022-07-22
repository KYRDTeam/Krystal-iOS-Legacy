//
//  SignTransactionObject.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import BigInt
import TrustCore
import TrustKeystore
import KrystalWallets

struct SignTransactionObject: Codable {
  let value: String
  let from: String
  let to: String?
  var nonce: Int
  let data: Data
  let gasPrice: String
  let gasLimit: String
  let chainID: Int
  let reservedGasLimit: String
  
  mutating func updateNonce(nonce: Int) {
    self.nonce = nonce
  }
}

extension SignTransactionObject {
  
  func toSignTransaction(address: KAddress, setting: ConfirmAdvancedSetting? = nil) -> SignTransaction {
    if let unwrap = setting {
      var nonceInt = self.nonce
      if let unwrapSetting = unwrap.advancedNonce {
        nonceInt = unwrapSetting
      }
      
      var gasLimitBigInt = BigInt(self.gasLimit)
      if let unwrapSetting = unwrap.advancedGasLimit {
        gasLimitBigInt = BigInt(unwrapSetting)
      }
      
      var gasPriceBigInt = BigInt(self.gasPrice)
      if let unwrapSetting = unwrap.avancedMaxFee {
        gasPriceBigInt = unwrapSetting.shortBigInt(units: UnitConfiguration.gasPriceUnit)
      }
      
      return SignTransaction(
        value: BigInt(self.value) ?? BigInt(0),
        address: address.addressString,
        to: self.to,
        nonce: nonceInt,
        data: self.data,
        gasPrice: gasPriceBigInt ?? BigInt.zero,
        gasLimit: gasLimitBigInt ?? BigInt.zero,
        chainID: self.chainID
      )
      
    } else {
      return SignTransaction(
        value: BigInt(self.value) ?? BigInt(0),
        address: address.addressString,
        to: self.to,
        nonce: self.nonce,
        data: self.data,
        gasPrice: BigInt(gasPrice) ?? BigInt(0),
        gasLimit: BigInt(gasLimit) ?? BigInt(0),
        chainID: self.chainID
      )
    }
  }
  func toSignTransaction(address: String, setting: ConfirmAdvancedSetting? = nil) -> SignTransaction {
    if let unwrap = setting {
      var nonceInt = self.nonce
      if let unwrapSetting = unwrap.advancedNonce {
        nonceInt = unwrapSetting
      }
      
      var gasLimitBigInt = BigInt(self.gasLimit)
      if let unwrapSetting = unwrap.advancedGasLimit {
        gasLimitBigInt = BigInt(unwrapSetting)
      }
      
      var gasPriceBigInt = BigInt(self.gasPrice)
      if let unwrapSetting = unwrap.avancedMaxFee {
        gasPriceBigInt = unwrapSetting.shortBigInt(units: UnitConfiguration.gasPriceUnit)
      }
      
      return SignTransaction(
        value: BigInt(self.value) ?? BigInt(0),
        address: address,
        to: self.to,
        nonce: nonceInt,
        data: self.data,
        gasPrice: gasPriceBigInt ?? BigInt.zero,
        gasLimit: gasLimitBigInt ?? BigInt.zero,
        chainID: self.chainID
      )
      
    } else {
      return SignTransaction(
        value: BigInt(self.value) ?? BigInt(0),
        address: address,
        to: self.to,
        nonce: self.nonce,
        data: self.data,
        gasPrice: BigInt(gasPrice) ?? BigInt(0),
        gasLimit: BigInt(gasLimit) ?? BigInt(0),
        chainID: self.chainID
      )
    }
  }
  
  func toEIP1559Transaction(setting: ConfirmAdvancedSetting) -> EIP1559Transaction {
    var nonceInt = self.nonce
    if let unwrap = setting.advancedNonce {
      nonceInt = unwrap
    }
    
    var gasLimitBigInt = BigInt(self.gasLimit)
    if let unwrap = setting.advancedGasLimit {
      gasLimitBigInt = BigInt(unwrap)
    }
    
    var maxGasBigInt = BigInt(self.gasPrice)
    if let unwrap = setting.avancedMaxFee {
      maxGasBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }
    
    var priorityFeeBigInt = (maxGasBigInt ?? BigInt.zero) - (KNGasCoordinator.shared.baseFee ?? BigInt.zero)
    if let unwrap = setting.advancedPriorityFee {
      priorityFeeBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt.zero
    }

    return EIP1559Transaction(
      chainID: BigInt(self.chainID).hexEncoded.hexSigned2Complement,
      nonce: BigInt(nonceInt).hexEncoded.hexSigned2Complement,
      gasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      maxInclusionFeePerGas: priorityFeeBigInt.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      toAddress: self.to ?? "",
      fromAddress: self.from,
      data: self.data.hexString.add0x,
      value: BigInt(self.value)?.hexEncoded.drop0x.hexSigned2Complement ?? "0x",
      reservedGasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x")
  }

  func gasPriceForCancelTransaction() -> BigInt {
    guard
      let currentGasPrice = BigInt(self.gasPrice)
    else
    {
      return KNGasConfiguration.gasPriceMax
    }
    let gasPrice = max(currentGasPrice * BigInt(1.2 * pow(10.0, 18.0)) / BigInt(10).power(18), KNGasConfiguration.gasPriceMax)
    return gasPrice
  }

  func toSpeedupTransaction(gasPrice: String, gasLimit: String) -> SignTransactionObject {
    return SignTransactionObject(value: self.value, from: self.from, to: self.to, nonce: self.nonce, data: self.data, gasPrice: gasPrice, gasLimit: gasLimit, chainID: self.chainID, reservedGasLimit: gasLimit)
  }

  func toCancelTransaction(gasPrice: String, gasLimit: String) -> SignTransactionObject {
    return SignTransactionObject(value: "0", from: self.from, to: self.from, nonce: self.nonce, data: Data(), gasPrice: gasPrice, gasLimit: gasLimit, chainID: self.chainID, reservedGasLimit: gasLimit)
  }

  func toSpeedupTransaction(account: Account, gasPrice: BigInt) -> SignTransaction {
    return SignTransaction(
      value: BigInt(self.value) ?? BigInt(0),
      account: account,
      to: self.to,
      nonce: self.nonce,
      data: self.data,
      gasPrice: gasPrice,
      gasLimit: BigInt(gasLimit) ?? BigInt(0),
      chainID: self.chainID
    )
  }
  
  func toCancelTransaction(account: Account) -> SignTransaction {
    return SignTransaction(
      value: BigInt(0),
      account: account,
      to: account.address.description,
      nonce: self.nonce,
      data: Data(),
      gasPrice: self.gasPriceForCancelTransaction(),
      gasLimit: KNGasConfiguration.transferETHGasLimitDefault,
      chainID: self.chainID
    )
  }
  
  func transactionGasPrice() -> BigInt? {
    return BigInt(self.gasPrice)
  }
}
