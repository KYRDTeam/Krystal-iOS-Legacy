//
//  SwapTransactionSettings.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/08/2022.
//

import Foundation
import BigInt

struct SwapTransactionSettings {
  var slippage: Double
  var basic: BasicTransactionSettings?
  var advanced: AdvancedTransactionSettings?
  var expertModeOn: Bool = false
  
  static func getDefaultSettings() -> SwapTransactionSettings {
    let slippage = UserDefaults.standard.double(forKey: Constants.slippageRateSaveKey)
    return SwapTransactionSettings(
      slippage: slippage > 0 ? slippage : 0.5,
      basic: BasicTransactionSettings(gasPriceType: .medium),
      advanced: nil,
      expertModeOn: UserDefaults.standard.bool(forKey: Constants.expertModeSaveKey)
    )
  }
  
}

struct AdvancedTransactionSettings {
  var gasLimit: BigInt
  var maxFee: BigInt
  var maxPriorityFee: BigInt
  var nonce: Int
}

struct BasicTransactionSettings {
  var gasPriceType: KNSelectedGasPriceType
}
