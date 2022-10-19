//
//  GasConfig.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BigInt

public protocol GasConfig {
    var lowGas: BigInt { get }
    var standardGas: BigInt { get }
    var fastGas: BigInt { get }
    var superFastGas: BigInt { get }
    
    var lowPriorityFee: BigInt? { get }
    var standardPriorityFee: BigInt? { get }
    var fastPriorityFee: BigInt? { get }
    var superFastPriorityFee: BigInt? { get }
    var baseFee: BigInt? { get }
    
    var defaultExchangeGasLimit: BigInt { get }
    var defaultTransferGasLimit: BigInt { get }
}
