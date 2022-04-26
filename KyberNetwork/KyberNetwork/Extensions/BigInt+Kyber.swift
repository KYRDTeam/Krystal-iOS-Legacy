// Copyright SIX DAY LLC. All rights reserved.

import BigInt

extension BigInt {
  
  static var etherFormatterCache: [PairKey<Int, Int>: EtherNumberFormatter] = [:]

  func getFormatter(minFractionDigits: Int, maxFractionDigits: Int) -> EtherNumberFormatter {
    if let formatter = BigInt.etherFormatterCache[PairKey(key1: minFractionDigits, key2: maxFractionDigits)] {
      return formatter
    } else {
      let formatter = EtherNumberFormatter()
      formatter.maximumFractionDigits = maxFractionDigits
      formatter.minimumFractionDigits = minFractionDigits
      BigInt.etherFormatterCache[PairKey(key1: minFractionDigits, key2: maxFractionDigits)] = formatter
      return formatter
    }
  }
  
  func string(units: EthereumUnit, minFractionDigits: Int, maxFractionDigits: Int) -> String {
    let formatter = getFormatter(minFractionDigits: minFractionDigits, maxFractionDigits: maxFractionDigits)
    return formatter.string(from: self, units: units)
  }

  func string(decimals: Int, minFractionDigits: Int, maxFractionDigits: Int) -> String {
    let formatter = getFormatter(minFractionDigits: minFractionDigits, maxFractionDigits: maxFractionDigits)
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
}
