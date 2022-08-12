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
  
  static let `default` = SwapTransactionSettings(
    slippage: 0.5,
    basic: BasicTransactionSettings(gasPriceType: .medium),
    advanced: nil,
    expertModeOn: false
  )
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
