//
//  StringUtils.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 21/07/2022.
//

import Foundation

class StringUtils {
  
  static func concat(strings: [String], normalJoinSeparator: String, lastJoinSeparator: String) -> String {
    if strings.isEmpty {
      return ""
    }
    if strings.count == 1 {
      return strings[0]
    }
    let first = strings.dropLast().joined(separator: normalJoinSeparator)
    let last = strings.last!
    
    return [first, last].joined(separator: lastJoinSeparator)
  }
  
}
