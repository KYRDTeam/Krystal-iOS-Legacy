//
//  String+number.swift
//  Utilities
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BigInt

public extension String {
    
    var hex: String {
        let data = self.data(using: .utf8)!
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    var hexEncoded: String {
        let data = self.data(using: .utf8)!
        return data.hexEncoded
    }
    
    func toDouble() -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        if let result = formatter.number(from: self.removeGroupSeparator(groupingSeparator: formatter.groupingSeparator)) {
            return result.doubleValue
        }
        return nil
    }
    
    var doubleValue: Double {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        if let result = formatter.number(from: self.removeGroupSeparator(groupingSeparator: formatter.groupingSeparator)) {
            return result.doubleValue
        }
        return 0
    }
    
    var trimmed: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var asDictionary: [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
                return [:]
            }
        }
        return [:]
    }
    
    var drop0x: String {
        if self.count > 2 && self.substring(with: 0..<2) == "0x" {
            return String(self.dropFirst(2))
        }
        return self
    }
    
    var add0x: String {
        return "0x" + self
    }
    
    func trunc(length: Int, trailing: String = "…") -> String {
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
    //Hex signed 2's complement
    var hexSigned2Complement: String {
        let string = self.drop0x
        if string.count % 2 != 0 {
            return "0" + string
        } else {
            return string
        }
    }
    
    var shortTypeAddress: String {
        return "\(self.prefix(8))...\(self.suffix(4))"
    }
}

public extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}

public extension String {
    
    func toBeLocalised() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    var jsonValue: Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
    
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                break
            }
            position = index(after: after)
        }
        return indices
    }
    
    func ranges(of searchString: String) -> [Range<String.Index>] {
        let _indices = indices(of: searchString)
        let count = searchString.count
        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
    }
    
    var bigInt: BigInt? {
        return BigInt(self)
    }
}

public extension String {
    
    func replacing(pattern: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return self
        }
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.count), withTemplate: "")
    }
    
    func whenEmpty(_ value: String) -> String {
        if isEmpty {
            return value
        }
        return self
    }
    
    func removeGroupSeparator() -> String {
        return self.replacingOccurrences(of: EtherNumberFormatter.short.groupingSeparator, with: "")
    }
    
    func removeGroupSeparator(groupingSeparator: String) -> String {
        return self.replacingOccurrences(of: groupingSeparator, with: "")
    }
    
    func cleanStringToNumber() -> String {
        let decimals: Character = EtherNumberFormatter.short.decimalSeparator.first!
        var valueString = ""
        var hasDecimals: Bool = false
        for char in self {
            if (char >= "0" && char <= "9") || (char == decimals && !hasDecimals) {
                valueString += "\(char)"
                if char == decimals { hasDecimals = true }
            }
        }
        return valueString
    }
    
    func shortBigInt(decimals: Int) -> BigInt? {
        if let double = Double(self) {
            return BigInt(double * pow(10.0, Double(decimals)))
        }
        return EtherNumberFormatter.short.number(
            from: self.removeGroupSeparator(),
            decimals: decimals
        )
    }
    
    func shortBigInt(units: EthereumUnit) -> BigInt? {
        if let double = Double(self) {
            return BigInt(double * Double(units.rawValue))
        }
        return EtherNumberFormatter.short.number(
            from: self.removeGroupSeparator(),
            units: units
        )
    }
    
    func fullBigInt(decimals: Int) -> BigInt? {
        if let double = Double(self) {
            return BigInt(double * pow(10.0, Double(decimals)))
        }
        return EtherNumberFormatter.full.number(
            from: self.removeGroupSeparator(),
            decimals: decimals
        )
    }
    
    func fullBigInt(units: EthereumUnit) -> BigInt? {
        if let double = Double(self) {
            return BigInt(double * Double(units.rawValue))
        }
        return EtherNumberFormatter.full.number(
            from: self.removeGroupSeparator(),
            units: units
        )
    }
    
    func amountBigInt(decimals: Int) -> BigInt? {
        return EtherNumberFormatter.full.number(
            from: self.removeGroupSeparator(),
            decimals: decimals
        )
    }
    
    func amountBigInt(units: EthereumUnit) -> BigInt? {
        return EtherNumberFormatter.full.number(
            from: self.removeGroupSeparator(),
            units: units
        )
    }
    
    func formatName(maxLen: Int = 10) -> String {
        if self.count <= maxLen { return self }
        return "\(self.prefix(maxLen))..."
    }
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    func isValidPassword() -> Bool {
        let passRegEx = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)[A-Za-z\\d$@$!%*#?&]{8,}$"
        let passTest = NSPredicate(format: "SELF MATCHES %@", passRegEx)
        return passTest.evaluate(with: self)
    }
    
    var hexaToBytes: [UInt8] {
        let hexa = Array(self)
        return stride(from: 0, to: count, by: 2).compactMap { UInt8(String(hexa[$0...$0.advanced(by: 1)]), radix: 16) }
    }
    
    static func isCurrentVersionHigher(currentVersion: String, compareVersion: String) -> Bool {
        let comps1 = currentVersion.components(separatedBy: ".")
        let comps2 = compareVersion.components(separatedBy: ".")
        if comps1.count != 3 || comps2.count != 3 { return true }
        guard let val11 = Int(comps1[0]), let val12 = Int(comps1[1]), let val13 = Int(comps1[2]) else { return true }
        let value1 = val11 * 1000000 + val12 * 1000 + val13
        guard let val21 = Int(comps2[0]), let val22 = Int(comps2[1]), let val23 = Int(comps2[2]) else { return true }
        let value2 = val21 * 1000000 + val22 * 1000 + val23
        return value1 >= value2
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    func dataFromHex() -> Data? {
        let string = self.drop0x
        if string.isEmpty { return Data() }
        var data = Data(capacity: string.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: string, range: NSRange(string.startIndex..., in: string)) { match, _, _ in
            let byteString = (string as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        
        guard !data.isEmpty else { return nil }
        
        return data
    }
    
    func formatMarketPairString() -> String {
        let tokens = self.components(separatedBy: "_")
        var left = tokens.first ?? ""
        var right = tokens.last ?? ""
        if left == "ETH" {
            left = "WETH"
        }
        if right == "ETH" {
            right = "WETH"
        }
        return "\(left)_\(right)"
    }
    
    func paddingString() -> String {
        return "  " + self + "  "
    }
    
    var toHexData: Data {
        if self.hasPrefix("0x") {
            return Data(_hex: self, chunkSize: 100)
        } else {
            return Data(_hex: self.hex, chunkSize: 100)
        }
    }
    
    var has0xPrefix: Bool {
        return hasPrefix("0x")
    }
    
    func limit(scope: Int) -> String {
        guard self.count > scope else {
            let number = scope - self.count
            if number == 0 {
                return self
            }
            var padding = ""
            for _ in 1...number {
                padding += " "
            }
            return self + padding
        }
        return String(self.prefix(scope - 3)) + "..."
    }
    
    var isHexEncoded: Bool {
        guard starts(with: "0x") else {
            return false
        }
        let regex = try! NSRegularExpression(pattern: "^0x[0-9A-Fa-f]*$")
        if regex.matches(in: self, range: NSRange(startIndex..., in: self)).isEmpty {
            return false
        }
        return true
    }
    
    var isTrustPK: Bool {
        return self.count == 64
    }
    
    var isSoletPrivateKey: Bool {
        let checkPrefix = self.hasPrefix("[")
        let checkSufFix = self.hasSuffix("]")
        
        return checkPrefix && checkSufFix
    }
    
    var isSoletPKVaild: Bool {
        guard self.isSoletPrivateKey else { return false }
        
        let stringList = self.dropFirst().dropLast().split(separator: ",")
        return stringList.count == 64
    }
    
    var isValidURL: Bool {
        if let url = URL(string: self) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
}

public extension StringProtocol {
    
    public func chunked(into size: Int) -> [SubSequence] {
        var chunks: [SubSequence] = []
        
        var i = startIndex
        
        while let nextIndex = index(i, offsetBy: size, limitedBy: endIndex) {
            chunks.append(self[i ..< nextIndex])
            i = nextIndex
        }
        
        let finalChunk = self[i ..< endIndex]
        
        if finalChunk.isEmpty == false {
            chunks.append(finalChunk)
        }
        
        return chunks
    }
}
