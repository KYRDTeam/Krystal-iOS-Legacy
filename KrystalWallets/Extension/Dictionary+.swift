//
//  Dictionary+.swift
//  KrystalWallets
//
//  Created by Tung Nguyen on 22/06/2022.
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
  var jsonString: String? {
    if let dict = (self as AnyObject) as? [String: AnyObject] {
      do {
        let data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions(rawValue: 0))
        if let string = String(data: data, encoding: String.Encoding.utf8) {
          return string
        }
      } catch {
        print(error)
      }
    }
    return nil
  }
}
