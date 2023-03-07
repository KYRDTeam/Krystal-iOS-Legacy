//
//  Double+.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 04/01/2023.
//

import Foundation
import BigInt

public extension Double {
    /// Rounds the double to decimal places value
    func roundedValue(toPlaces places: Int = 2) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    func amountBigInt(decimals: Int) -> BigInt? {
        var memory = decimals
        var tempDoubleValue = self
        
        while (tempDoubleValue != floor(tempDoubleValue) && memory > 0) {
            tempDoubleValue *= 10
            memory -= 1
        }
        return BigInt(tempDoubleValue) * BigInt(10).power(memory)
    }
}
