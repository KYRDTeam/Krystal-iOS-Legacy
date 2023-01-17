//
//  SettingAdvancedModeFormCellModel.swift
//  SwapModule
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation
import BigInt
import Dependencies
import Utilities
import AppState
import TransactionModule
import Services

class SettingAdvancedModeFormCellModel {
  var maxPriorityFeeString: String = ""
  var maxFeeString: String = ""
  var gasLimitString: String
  var customNonceString: String = ""
  
  var maxPriorityFeeChangedHandler: (String) -> Void = { _ in }
  var maxFeeChangedHandler: (String) -> Void = { _ in }
  var gasLimitChangedHandler: (String) -> Void = { _ in }
  var customNonceChangedHander: (String) -> Void = { _ in }
  var tapTitleWithIndex: (Int) -> Void = { _ in }
  
  var gasLimit: BigInt
  var nonce: Int {
    didSet {
      self.customNonceString = "\(self.nonce)"
    }
  }
  
  var customNonceValue: Int {
    return Int(customNonceString) ?? 0
  }
    
  let rate: Rate?

  init(gasLimit: BigInt, nonce: Int, rate: Rate?) {
    self.gasLimit = gasLimit
    self.nonce = nonce
    self.gasLimitString = gasLimit.description
    self.rate = rate
  }
  
  func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
    return (self.maxPriorityFeeString, self.maxFeeString, self.gasLimitString)
  }
  
  func resetData() {
    gasLimitString = gasLimit.description
    maxPriorityFeeString = ""
    maxFeeString = ""
    customNonceString = "\(nonce)"
  }
  
  var maxPriorityErrorStatus: AdvancedInputError {
    guard !maxPriorityFeeString.isEmpty else {
      return .empty
    }

      let lowerLimit = AppDependencies.gasConfig.currentChainStandardPriorityFee ?? BigInt(0)
    let maxPriorityBigInt = maxPriorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)

    if maxPriorityBigInt < lowerLimit {
      return .low
    } else {
      return .none
    }
  }
  
  var maxFeeErrorStatus: AdvancedInputError {
    guard !maxFeeString.isEmpty else {
      return .empty
    }
      let baseFee = AppDependencies.gasConfig.getCurrentChainBaseFee ?? .zero
    let currentPriority = maxPriorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
    let standardFee = AppDependencies.gasConfig.currentChainStandardGasPrice
    
    let lowerLimit = baseFee + currentPriority
    let maxFee = maxFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)

    if maxFee < lowerLimit {
      return .low
    } else if maxFee < standardFee {
      return .high //This is label for case fee < standard fee
    } else {
      return .none
    }
  }
  
  var advancedGasLimitErrorStatus: AdvancedInputError {
    guard !gasLimitString.isEmpty, let gasLimit = BigInt(gasLimitString) else {
      return .empty
    }
    let estGasUsed = self.rate?.estGasConsumed ?? Int(TransactionConstants.lowestGasLimit)
    if gasLimit < BigInt(estGasUsed) {
      return .low
    } else {
      return .none
    }
  }
  
  var advancedNonceErrorStatus: AdvancedInputError {
    guard !customNonceString.isEmpty else {
      return .empty
    }

    let nonceInt = Int(customNonceString) ?? 0
    if nonceInt < 0 {
      return .low
    } else {
      return .none
    }
  }
  
  func hasNoError() -> Bool {
    return (maxPriorityErrorStatus == .none || maxPriorityErrorStatus == .low) && (maxFeeErrorStatus == .none || maxFeeErrorStatus == .high) && advancedGasLimitErrorStatus == .none && advancedNonceErrorStatus == .none
  }

}
