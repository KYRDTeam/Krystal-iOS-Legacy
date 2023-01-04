//
//  Double+.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 04/01/2023.
//

import Foundation

extension Double {
    /// Rounds the double to decimal places value
    func roundedValue(toPlaces places: Int = 2) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
