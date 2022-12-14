//
//  BigInt+.swift
//  Utilities
//
//  Created by Tung Nguyen on 14/10/2022.
//

import BigInt


public extension BigInt {
    var hexEncoded: String {
        return "0x" + String(self, radix: 16)
    }
}

public extension BigInt {
    
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
    
    func doubleValue(decimal: Int) -> Double {
        let doubleString = self.fullString(decimals: decimal)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: doubleString) {
            return number.doubleValue
        }
        return 0.0
    }
}
