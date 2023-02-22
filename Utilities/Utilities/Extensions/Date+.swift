//
//  Date+.swift
//  Utilities
//
//  Created by Com1 on 22/02/2023.
//

import Foundation
extension Date {
    public func currentTimeMillis() -> Double {
      return self.timeIntervalSince1970 * 1000
    }
}
