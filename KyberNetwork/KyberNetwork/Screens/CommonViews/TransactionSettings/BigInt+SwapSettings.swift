//
//  BigInt+SwapSettings.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 18/08/2022.
//

import Foundation
import BigInt

extension BigInt {
  func displayGWEI() -> String {
    return self.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2) + " Gwei"
  }
  
  func formatFeeString(gasLimit: BigInt, type: Int) -> String {
    if let usdRate = KNGeneralProvider.shared.quoteTokenPrice?.usd {
      let fee = self * gasLimit
      let usdAmt = fee * BigInt(usdRate * pow(10.0, 18.0)) / BigInt(10).power(18)
      let value = usdAmt.displayRate(decimals: 18)
      var typeString = ""
      switch type {
      case 3:
        if let est = KNSelectedGasPriceType.fast.getEstTime() {
          typeString = "\(est)s"
        }
      case 2:
        if let est = KNSelectedGasPriceType.medium.getEstTime() {
          typeString = "\(est)s"
        }
      case 1:
        if let est = KNSelectedGasPriceType.slow.getEstTime() {
          typeString = "\(est)s"
        }
      default:
        break
      }
      return "~$\(value) • \(typeString)"
    } else {
      return ""
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
