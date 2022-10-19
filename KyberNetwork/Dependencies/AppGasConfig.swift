//
//  AppGasConfig.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 17/10/2022.
//

import Foundation
import Dependencies
import BigInt

class AppGasConfig: GasConfig {
    
    var lowGas: BigInt {
        return KNGasCoordinator.shared.lowKNGas
    }
    
    var standardGas: BigInt {
        return KNGasCoordinator.shared.standardKNGas
    }
    
    var fastGas: BigInt {
        return KNGasCoordinator.shared.fastKNGas
    }
    
    var superFastGas: BigInt {
        return KNGasCoordinator.shared.superFastKNGas
    }
    
    var lowPriorityFee: BigInt? {
        return KNGasCoordinator.shared.lowPriorityFee
    }
    
    var standardPriorityFee: BigInt? {
        return KNGasCoordinator.shared.standardPriorityFee
    }
    
    var fastPriorityFee: BigInt? {
        return KNGasCoordinator.shared.fastPriorityFee
    }
    
    var superFastPriorityFee: BigInt? {
        return KNGasCoordinator.shared.superFastPriorityFee
    }
    
    var baseFee: BigInt? {
        return KNGasCoordinator.shared.baseFee
    }
    
    var defaultExchangeGasLimit: BigInt {
        return BigInt(650_000)
    }
    
    var defaultTransferGasLimit: BigInt {
        return BigInt(180_000)
    }

}
