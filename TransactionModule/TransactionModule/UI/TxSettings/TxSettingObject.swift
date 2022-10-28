//
//  TxSettingObject.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import BigInt

public enum GasType {
    case slow
    case regular
    case fast
    case superFast
}

public struct TxSettingObject {
    var basic: TxBasicSetting?
    var advanced: TxAdvancedSetting?
    
    public static let `default`: TxSettingObject = .init(basic: .init(gasType: .regular), advanced: nil)
}

public struct TxBasicSetting {
    var gasType: GasType = .regular
}

public struct TxAdvancedSetting {
    var gasLimit: BigInt
    var maxFee: BigInt
    var maxPriorityFee: BigInt
    var nonce: Int
}
