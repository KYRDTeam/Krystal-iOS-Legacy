//
//  BigInt+SwapSettings.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 18/08/2022.
//

import Foundation
import BigInt
import Utilities
import Services
import Dependencies

extension BigInt {
  func displayGWEI() -> String {
    return self.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2) + " Gwei"
  }
  
    func formatFeeString(type: Int, rate: Rate?, quoteTokenPrice: Double?) -> String {
    var typeString = ""
    switch type {
    case 3:
        if let est = AppDependencies.gasConfig.currentChainFastEstTime {
        typeString = "\(est)s"
      }
    case 2:
      if let est = AppDependencies.gasConfig.currentChainStandardEstTime {
        typeString = "\(est)s"
      }
    case 1:
      if let est = AppDependencies.gasConfig.currentChainSlowEstTime {
        typeString = "\(est)s"
      }
    default:
      break
    }
    if let usdRate = quoteTokenPrice, let gasLimit = rate?.estimatedGas {
      let fee = self * BigInt(gasLimit)
      let usdAmt = fee * BigInt(usdRate * pow(10.0, 18.0)) / BigInt(10).power(18)
      let usdString = NumberFormatUtils.gasFee(value: usdAmt)
      
      return "~$\(usdString) • \(typeString)"
    } else {
      return "\(typeString)"
    }
  }
  
  func formatFeeStringForType(gasLimit: BigInt, type: KNSelectedGasPriceType) -> String {
    let fee = self * gasLimit
    let value = fee.string(units: UnitConfiguration.gasFeeUnit, minFractionDigits: 0, maxFractionDigits: 2)
    var timeDisplay = ""
    let typeTimeDisplay = type.displayTime()
    if !typeTimeDisplay.isEmpty {
      timeDisplay = " ~ \(typeTimeDisplay)"
    }
    return "\(type.displayString().capitalized): \(value) GWEI" + timeDisplay
  }
}
