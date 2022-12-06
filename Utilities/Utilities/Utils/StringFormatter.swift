//
//  StringFormatter.swift
//  Utilities
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation

final public class StringFormatter {
    /// currencyFormatter of a `StringFormatter` to represent curent locale.
    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.currencySymbol = ""
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .currencyAccounting
        formatter.isLenient = true
        return formatter
    }()
    /// decimalFormatter of a `StringFormatter` to represent curent locale.
    private lazy var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        formatter.isLenient = true
        return formatter
    }()
    
    public static func percentString(value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .percent
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    public static func usdString(value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "")
    }
    
    static func currencyString(value: Double, symbol: String) -> String {
        var maxDigits = 2
        if symbol.lowercased() == "usd" {
            maxDigits = 2
        } else if symbol.lowercased() == "matic" {
            maxDigits = 2
        } else if symbol.lowercased() == "btc" {
            maxDigits = 5
        } else if symbol.lowercased() == "eth" {
            maxDigits = 4
        } else if symbol.lowercased() == "bnb" {
            maxDigits = 3
        } else if symbol.lowercased() == "avax" {
            maxDigits = 4
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maxDigits
        formatter.roundingMode = .floor
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    public static func amountString(value: Double) -> String {
        let formatter = NumberFormatter()
        // rule amount round upto 4 digits
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.roundingMode = .floor
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    func currencyString(value: Double, decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        formatter.roundingMode = .floor
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    /// Converts a Decimal to a `currency String`.
    ///
    /// - Parameters:
    ///   - value: Decimal to convert.
    ///   - currencyCode: code of the currency.
    /// - Returns: Currency `String` represenation.
    func currency(with value: Decimal, and currencyCode: String) -> String {
        let formatter = currencyFormatter
        formatter.currencyCode = currencyCode
        return formatter.string(for: value) ?? "\(value)"
    }
    /// Converts a Decimal to a `token String`.
    ///
    /// - Parameters:
    ///   - value: Decimal to convert.
    ///   - decimals: symbols after coma.
    /// - Returns: Token `String` represenation.
    func token(with value: Decimal, and decimals: Int) -> String {
        let formatter = decimalFormatter
        formatter.maximumFractionDigits = decimals
        return formatter.string(for: value) ?? "\(value)"
    }
    /// Converts a String to a `Decimal`.
    ///
    /// - Parameters:
    ///   - value: String to convert.
    /// - Returns: Decimal represenation.
    func decimal(with value: String) -> Decimal? {
        let formatter = decimalFormatter
        formatter.generatesDecimalNumbers = true
        formatter.decimalSeparator = Locale.current.decimalSeparator
        return formatter.number(from: value) as? Decimal
    }
    /// Converts a Double to a `String`.
    ///
    /// - Parameters:
    ///   - double: double to convert.
    ///   - precision: symbols after coma.
    /// - Returns: `String` represenation.
    func formatter(for double: Double, with precision: Int) -> String {
        return String(format: "%.\(precision)f", double)
    }
    /// Converts a Double to a `String`.
    ///
    /// - Parameters:
    ///   - double: double to convert.
    /// - Returns: `String` represenation.
    func formatter(for double: Double) -> String {
        return String(format: "%f", double)
    }
}
