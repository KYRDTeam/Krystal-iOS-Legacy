// Copyright SIX DAY LLC. All rights reserved.

import BigInt

extension String {

  func removeGroupSeparator() -> String {
    return self.replacingOccurrences(of: EtherNumberFormatter.short.groupingSeparator, with: "")
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

  func displayRate() -> String {
    return KNRateHelper.displayRate(from: self)
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
  
  func isNativeAddress() -> Bool {
    return self.lowercased() == Constants.ethAddress || self.lowercased() == Constants.bnbAddress
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
    guard self.count >= scope else { return self }
    return String(self.prefix(scope)) + "..."
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
}

extension StringProtocol {

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
