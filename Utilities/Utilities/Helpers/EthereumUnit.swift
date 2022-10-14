//
//  EthereumUnit.swift
//  Utilities
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation

public enum EthereumUnit: Int64 {
    case wei = 1
    case kwei = 1_000
    case gwei = 1_000_000_000
    case ether = 1_000_000_000_000_000_000
}

public extension EthereumUnit {
    var name: String {
        switch self {
        case .wei: return "Wei"
        case .kwei: return "Kwei"
        case .gwei: return "Gwei"
        case .ether: return "Ether"
        }
    }
}

public struct UnitConfiguration {
    public static let gasPriceUnit: EthereumUnit = .gwei
    public static let gasFeeUnit: EthereumUnit = .ether
}
