//
//  RateBasedGasLimitLoader.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/08/2022.
//

import Foundation
import BigInt
import Moya

protocol SwapGasLimitLoader {
  func getGasLimit(completion: @escaping (_ gasLimit: BigInt?) -> ())
}

