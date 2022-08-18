// Copyright SIX DAY LLC. All rights reserved.

import BigInt

extension BigInt {
  
  func string(units: EthereumUnit, minFractionDigits: Int, maxFractionDigits: Int) -> String {
    let formatter = EtherNumberFormatter()
    formatter.maximumFractionDigits = maxFractionDigits
    formatter.minimumFractionDigits = minFractionDigits
    return formatter.string(from: self, units: units)
  }

  func string(decimals: Int, minFractionDigits: Int, maxFractionDigits: Int) -> String {
    let formatter = EtherNumberFormatter()
    formatter.maximumFractionDigits = maxFractionDigits
    formatter.minimumFractionDigits = minFractionDigits
    return formatter.string(from: self, decimals: decimals)
  }

  func shortString(units: EthereumUnit, maxFractionDigits: Int = 5) -> String {
    let formatter = EtherNumberFormatter.short
    formatter.maximumFractionDigits = maxFractionDigits
    return formatter.string(from: self, units: units)
  }

  func shortString(decimals: Int, maxFractionDigits: Int = 5) -> String {
    let formatter = EtherNumberFormatter.short
    formatter.maximumFractionDigits = maxFractionDigits
    return formatter.string(from: self, decimals: decimals)
  }

  func fullString(units: EthereumUnit) -> String {
    return EtherNumberFormatter.full.string(from: self, units: units)
  }

  func fullString(decimals: Int) -> String {
    return self.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: decimals)
  }

  func displayRate(decimals: Int) -> String {
    return KNRateHelper.displayRate(from: self, decimals: decimals)
  }

  static func bigIntFromString(value: String) -> BigInt {
    return BigInt(stringLiteral: value)
  }
  
  func doubleUSDValue(currencyDecimal: Int) -> Double {
    let doubleString = self.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: currencyDecimal)
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = currencyDecimal
    if let number = formatter.number(from: doubleString) {
      return number.doubleValue
    }
    return 0.0
  }
  
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
