//
//  EtherNumberFormatter.swift
//  Utilities
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BigInt

final public class EtherNumberFormatter {
    /// Formatter that preserves full precision.
    public static let full = EtherNumberFormatter()
    
    // Formatter that caps the number of decimal digits to 4.
    public static let short: EtherNumberFormatter = {
        let formatter = EtherNumberFormatter()
        formatter.maximumFractionDigits = 4
        return formatter
    }()
    
    /// Minimum number of digits after the decimal point.
    var minimumFractionDigits = 0
    
    /// Maximum number of digits after the decimal point.
    var maximumFractionDigits = Int.max
    
    /// Decimal point.
    public var decimalSeparator = "."
    
    /// Thousands separator.
    public var groupingSeparator = ","
    
    /// Initializes a `EtherNumberFormatter` with a `Locale`.
    init(locale: Locale = .current) {
        decimalSeparator = locale.decimalSeparator ?? "."
        groupingSeparator = locale.groupingSeparator ?? ","
    }
    
    /// Converts a string to a `BigInt`.
    ///
    /// - Parameters:
    ///   - string: string to convert
    ///   - units: units to use
    /// - Returns: `BigInt` represenation.
    public func number(from string: String, units: EthereumUnit = .ether) -> BigInt? {
        let decimals = Int(log10(Double(units.rawValue)))
        return number(from: string, decimals: decimals)
    }
    
    /// Converts a string to a `BigInt`.
    ///
    /// - Parameters:
    ///   - string: string to convert
    ///   - decimals: decimal places used for scaling values.
    /// - Returns: `BigInt` represenation.
    public func number(from string: String, decimals: Int) -> BigInt? {
        guard let index = string.index(where: { String($0) == decimalSeparator }) else {
            // No fractional part
            return BigInt(string).flatMap({ $0 * BigInt(10).power(decimals) })
        }
        
        let fractionalDigits = string.distance(from: string.index(after: index), to: string.endIndex)
        if fractionalDigits > decimals {
            // Can't represent number accurately
            return nil
        }
        
        var fullString = string
        fullString.remove(at: index)
        
        guard let number = BigInt(fullString) else {
            return nil
        }
        
        if fractionalDigits < decimals {
            return number * BigInt(10).power(decimals - fractionalDigits)
        } else {
            return number
        }
    }
    
    /// Formats a `BigInt` for displaying to the user.
    ///
    /// - Parameters:
    ///   - number: number to format
    ///   - units: units to use
    /// - Returns: string representation
    public func string(from number: BigInt, units: EthereumUnit = .ether) -> String {
        let decimals = Int(log10(Double(units.rawValue)))
        return string(from: number, decimals: decimals)
    }
    
    /// Formats a `BigInt` for displaying to the user.
    ///
    /// - Parameters:
    ///   - number: number to format
    ///   - decimals: decimal places used for scaling values.
    /// - Returns: string representation
    public func string(from number: BigInt, decimals: Int) -> String {
        precondition(minimumFractionDigits >= 0)
        precondition(maximumFractionDigits >= 0)
        
        let dividend = BigInt(10).power(decimals)
        let (integerPart, remainder) = number.quotientAndRemainder(dividingBy: dividend)
        let integerString = self.integerString(from: integerPart)
        let fractionalString = self.fractionalString(from: BigInt(sign: .plus, magnitude: remainder.magnitude), decimals: decimals)
        if fractionalString.isEmpty {
            return integerString
        }
        return "\(integerString)\(self.decimalSeparator)\(fractionalString)"
    }
    /// Formats a `BigInt` to a Decimal.
    ///
    /// - Parameters:
    ///   - number: number to format
    ///   - decimals: decimal places used for scaling values.
    /// - Returns: Decimal representation
    public func decimal(from number: BigInt, decimals: Int) -> Decimal? {
        precondition(minimumFractionDigits >= 0)
        precondition(maximumFractionDigits >= 0)
        let dividend = BigInt(10).power(decimals)
        let (integerPart, remainder) = number.quotientAndRemainder(dividingBy: dividend)
        let integerString = integerPart.description
        let fractionalString = self.fractionalString(from: BigInt(sign: .plus, magnitude: remainder.magnitude), decimals: decimals)
        if fractionalString.isEmpty {
            return Decimal(string: integerString)
        }
        return Decimal(string: "\(integerString)\(self.decimalSeparator)\(fractionalString)")
    }
    private func integerString(from: BigInt) -> String {
        var string = from.description
        let end = from.sign == .minus ? 1 : 0
        for offset in stride(from: string.count - 3, to: end, by: -3) {
            let index = string.index(string.startIndex, offsetBy: offset)
            string.insert(contentsOf: groupingSeparator, at: index)
        }
        return string
    }
    
    private func fractionalString(from number: BigInt, decimals: Int) -> String {
        var number = number
        let digits = number.description.count
        
        if number == 0 || decimals - digits >= maximumFractionDigits {
            // Value is smaller than can be represented with `maximumFractionDigits`
            return String(repeating: "0", count: minimumFractionDigits)
        }
        
        if decimals < minimumFractionDigits {
            number *= BigInt(10).power(minimumFractionDigits - decimals)
        }
        if decimals > maximumFractionDigits {
            number /= BigInt(10).power(decimals - maximumFractionDigits)
        }
        
        var string = number.description
        if digits < decimals {
            // Pad with zeros at the left if necessary
            string = String(repeating: "0", count: decimals - digits) + string
        }
        
        // Remove extra zeros after the decimal point.
        if let lastNonZeroIndex = string.reversed().index(where: { $0 != "0" })?.base {
            let numberOfZeros = string.distance(from: string.startIndex, to: lastNonZeroIndex)
            if numberOfZeros > minimumFractionDigits {
                let newEndIndex = string.index(string.startIndex, offsetBy: numberOfZeros - minimumFractionDigits)
                string = String(string[string.startIndex..<newEndIndex])
            }
        }
        
        return string
    }
}
