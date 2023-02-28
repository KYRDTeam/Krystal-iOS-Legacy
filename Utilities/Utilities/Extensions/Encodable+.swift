//
//  Encodable+.swift
//  Utilities
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
public extension Encodable {
  func asDictionary() -> [String: Any] {
    let data = try? JSONEncoder().encode(self)
    guard let data = data, let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
        return [:]
    }
      return dictionary ?? [:]
  }
}
