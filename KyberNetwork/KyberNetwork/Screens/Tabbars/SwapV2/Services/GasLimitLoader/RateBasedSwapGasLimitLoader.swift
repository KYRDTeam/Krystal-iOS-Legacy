//
//  RateBasedSwapGasLimitLoader.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/08/2022.
//

import Foundation
import BigInt

class RateBasedSwapGasLimitLoader: SwapGasLimitLoader {
  var rate: Rate
  
  init(rate: Rate) {
    self.rate = rate
  }
  
  func getGasLimit(completion: @escaping (_ gasLimit: BigInt?) -> ()) {
    
  }
  
}
