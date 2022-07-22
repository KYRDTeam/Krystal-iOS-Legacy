//
//  GasCalculator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/06/2022.
//

import Foundation
import BigInt

protocol GasCalculator {
  var defaultGasFee: BigInt { get }
  
  func getGasFee(completion: @escaping (BigInt) -> ())
}

