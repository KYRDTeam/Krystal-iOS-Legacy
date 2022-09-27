//
//  NumberFormatUtils.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 08/08/2022.
//

import Foundation
import BigInt

public struct FormatDecimal {
  public static let balanceDecimals = 6
}

class NumberFormatUtils {
  
  static let withSeparator: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = .current
    return formatter
  }()
  
  // Get grouping and decimal separator
  static let separator: (grouping: String, decimal: String) = {
    return (withSeparator.groupingSeparator ?? ",", withSeparator.decimalSeparator ?? "")
  }()
  
  static func percent(value: Double, maxDecimalDigits: Int = 2) -> String {
    let valueBigInt = BigInt(value * pow(10.0, Double(maxDecimalDigits)))
    return format(value: valueBigInt, decimals: maxDecimalDigits, maxDecimalMeaningDigits: nil, maxDecimalDigits: maxDecimalDigits) + "%"
  }

  static func rate(value: BigInt, decimals: Int) -> String {
    return format(value: value, decimals: decimals, maxDecimalMeaningDigits: 4, maxDecimalDigits: nil)
  }
  
  static func gasFee(value: BigInt) -> String {
    if String(value).count > 18 {
      return format(value: value, decimals: 18, maxDecimalMeaningDigits: 2, maxDecimalDigits: 2)
    } else {
      return format(value: value, decimals: 18, maxDecimalMeaningDigits: 4, maxDecimalDigits: 8)
    }
  }
  
  static func amount(value: BigInt, decimals: Int) -> String {
    return format(value: value, decimals: decimals, maxDecimalMeaningDigits: 6, maxDecimalDigits: 6)
  }
  
  static func usdAmount(value: BigInt, decimals: Int) -> String {
    return format(value: value, decimals: decimals, maxDecimalMeaningDigits: nil, maxDecimalDigits: 2)
  }
  
  static func zeroPlaceHolder(decimalDigits: Int = 2) -> String {
    let decimalPart = [String](repeating: "0", count: decimalDigits).joined()
    return "0" + separator.decimal + decimalPart
  }
  
  static func format(value: BigInt, decimals: Int, maxDecimalMeaningDigits: Int?, maxDecimalDigits: Int?) -> String {
    if value.isZero {
      return "0"
    }
    
    var stringValue = String(value)
    
    // Fill zeros to leading
    let maxTotalDigits = decimals + 1 // For 0 before .
    let missingDigits = maxTotalDigits - stringValue.count
    if missingDigits > 0 {
      let prefixZeros = [String](repeating: "0", count: missingDigits).joined()
      stringValue = prefixZeros + stringValue
    }
    let suffix = stringValue.suffix(decimals)
    stringValue = stringValue.dropLast(decimals) + separator.decimal + suffix
    
    let components = stringValue.components(separatedBy: separator.decimal)
    
    if components.count > 1 {
      let beforeDot = components.first!
      let afterDot = components.last!
      var totalLeadingZeros = 0
      
      for char in afterDot {
        if char != "0" {
          break
        } else {
          totalLeadingZeros += 1
        }
      }
      
      var decimalPart: String = ""
      if let maxDecimalMeaningDigits = maxDecimalMeaningDigits {
        if let maxDecimalDigits = maxDecimalDigits {
          decimalPart = String(afterDot.prefix(totalLeadingZeros + maxDecimalMeaningDigits).prefix(maxDecimalDigits))
        } else {
          decimalPart = String(afterDot.prefix(totalLeadingZeros + maxDecimalMeaningDigits))
        }
      } else if let maxDecimalDigits = maxDecimalDigits {
        decimalPart = String(afterDot.prefix(maxDecimalDigits))
      } else {
        decimalPart = afterDot
      }
      
      let integerPath = withSeparator.string(from: (Int(beforeDot) ?? 0) as NSNumber) ?? "0"
      stringValue = integerPath + separator.decimal + decimalPart
    }
    
    // Remove leading zeros
    while stringValue.first == "0" {
      stringValue.removeFirst()
    }
    if stringValue.first == separator.decimal.first {
      stringValue = "0" + stringValue
    }
    
    // Remove trailing zeros
    while stringValue.last == "0" {
      stringValue.removeLast()
    }
    if stringValue.last == separator.decimal.first {
      stringValue.removeLast()
    }
    
    return stringValue
  }

  static func balanceFormat(value: BigInt, decimals: Int) -> String {
    return NumberFormatUtils.format(value: value, decimals: decimals, maxDecimalMeaningDigits: FormatDecimal.balanceDecimals, maxDecimalDigits: FormatDecimal.balanceDecimals)
  }
  
  static func volFormat(number: Double) -> String {
    let thousand = number / 1000
    let million = number / 1000000
    let billion = number / 1000000000
    
    let trillion = number / 1000000000000
    let quadrillion = number / 1000000000000000
    let quintillion = number / 1000000000000000000
    
    if quintillion >= 1.0 {
      return "\(round(quintillion*10)/10)Q"
    } else if quadrillion >= 1.0 {
      return "\(round(quadrillion*10)/10)q"
    } else if trillion >= 1.0 {
      return ("\(round(trillion*10/10))t")
    } else if billion >= 1.0 {
      return "\(round(billion*10)/10)B"
    } else if million >= 1.0 {
      return "\(round(million*10)/10)M"
    } else if thousand >= 1.0 {
      return ("\(round(thousand*10/10))K")
    } else {
      return "\(Int(number))"
    }
  }
  
  static func valueFormat(value: BigInt, decimals: Int, currencyMode: CurrencyMode) -> String {
    switch currencyMode {
    case .usd:
      return format(value: value, decimals: decimals, maxDecimalMeaningDigits: nil, maxDecimalDigits: 2)
    case .eth:
      return format(value: value, decimals: decimals, maxDecimalMeaningDigits: nil, maxDecimalDigits: 7)
    case .btc:
      return format(value: value, decimals: decimals, maxDecimalMeaningDigits: nil, maxDecimalDigits: 8)
    case .quote:
      var maxDecimal = 3
      if KNGeneralProvider.shared.currentChain == .bsc {
        maxDecimal = 6
      } else if KNGeneralProvider.shared.currentChain == .avalanche {
        maxDecimal = 5
      }
      return format(value: value, decimals: decimals, maxDecimalMeaningDigits: nil, maxDecimalDigits: maxDecimal)
    }
    
  }
  
  static func allTimeHighAndLowFormat(number: Double) -> String {
    if number < 1 {
      return format(value: BigInt(number * pow(10.0, 18.0)), decimals: 18, maxDecimalMeaningDigits: 3, maxDecimalDigits: 8)
    } else {
      return format(value: BigInt(number * pow(10.0, 18.0)), decimals: 18, maxDecimalMeaningDigits: nil, maxDecimalDigits: 2)
    }
  }
}
