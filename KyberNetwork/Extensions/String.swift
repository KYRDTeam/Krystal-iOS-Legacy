// Copyright SIX DAY LLC. All rights reserved.

import Foundation

extension String {
    var hex: String {
        let data = self.data(using: .utf8)!
        return data.map { String(format: "%02x", $0) }.joined()
    }

    var hexEncoded: String {
        let data = self.data(using: .utf8)!
        return data.hexEncoded
    }

  var doubleValue: Double {
    let decimalSeparator = Locale.current.decimalSeparator ?? "."
    let groupSeparator = Locale.current.groupingSeparator ?? ","
    let formatter = NumberFormatter()
    formatter.locale = Locale.current
    formatter.decimalSeparator = decimalSeparator
    
    let refineTxt = self.replacingOccurrences(of: groupSeparator, with: "")
    
    if let result = formatter.number(from: refineTxt) {
      return result.doubleValue
    } else {
      formatter.decimalSeparator = ","
      if let result = formatter.number(from: refineTxt) {
        return result.doubleValue
      }
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
    var string = self.drop0x
    if string.count % 2 != 0 {
      return "0" + string
    } else {
      return string
    }
  }
}

extension String {
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

extension String {

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
}
