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
    public var basic: TxBasicSetting?
    public var advanced: TxAdvancedSetting?
    
    public static let `default`: TxSettingObject = .init(basic: .init(gasType: .regular), advanced: nil)
}

public struct TxBasicSetting {
    public var gasType: GasType = .regular
}

public struct TxAdvancedSetting {
    public var gasLimit: BigInt
    public var maxFee: BigInt
    public var maxPriorityFee: BigInt
    public var nonce: Int
}
