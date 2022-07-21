// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

extension Double {
  
  func rounded(to places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
  
  func amountBigInt(decimals: Int) -> BigInt? {
    return BigInt(self * pow(10.0, Double(decimals)))
  }
}
