//
//  EthGasCalculator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/06/2022.
//

import Foundation
import BigInt

class EthGasCalculator: GasCalculator {
  
  var defaultGasFee: BigInt {
    let gasPrice = KNGasCoordinator.shared.standardKNGas
    let gasLimit = KNGasConfiguration.transferETHGasLimitDefault
    return gasPrice * gasLimit
  }
  
  func getGasFee(completion: @escaping (BigInt) -> ()) {
    
  }
  
}

