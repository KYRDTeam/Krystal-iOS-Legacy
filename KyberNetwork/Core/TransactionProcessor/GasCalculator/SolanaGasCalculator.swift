//
//  SolanaGasCalculator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/06/2022.
//

import Foundation
import BigInt

class SolanaGasCalculator: GasCalculator {
  
  var defaultGasFee: BigInt {
    let lamportPerSignature = BigInt(5000)
    let defaultMinimumRentExemption = BigInt(2039280)
    return lamportPerSignature * defaultMinimumRentExemption
  }
  
  func getGasFee(completion: @escaping (BigInt) -> ()) {
    
  }
}

