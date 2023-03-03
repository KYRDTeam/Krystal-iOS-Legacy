// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

extension Double {
  
  func rounded(to places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
  
  func amountBigInt(decimals: Int) -> BigInt? {
      var memory = decimals
      var tempDoubleValue = self
      
      while (tempDoubleValue != floor(tempDoubleValue)) {
          tempDoubleValue *= 10
          memory -= 1
      }
      return BigInt(tempDoubleValue) * BigInt(10).power(memory)
  }
}
