//
//  KNSelectedGasPriceType.swift
//  SwapModule
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Dependencies
import BigInt

enum KNSelectedGasPriceType: Int {
    case fast = 0
    case medium = 1
    case slow = 2
    case superFast = 3
    case custom
    
    func getGasValue() -> BigInt {
        switch self {
        case .fast:
            return AppDependencies.gasConfig.currentChainFastGasPrice
        case .medium:
            return AppDependencies.gasConfig.currentChainStandardGasPrice
        case .slow:
            return AppDependencies.gasConfig.currentChainLowGasPrice
        case .superFast:
            return AppDependencies.gasConfig.currentChainSuperFastGasPrice
        case .custom:
            return .zero
        }
    }
    
    func displayString() -> String {
        switch self {
        case .fast:
            return "fast"
        case .medium:
            return "regular"
        case .slow:
            return "slow"
        case .superFast:
            return "super fast"
        case .custom:
            return "custom"
        }
    }
    
    func displayTime() -> String {
        switch self {
        case .fast:
            return "30s"
        case .medium:
            return "45s"
        case .slow:
            return "10m"
        case .superFast:
            return ""
        case .custom:
            return ""
        }
    }
}
