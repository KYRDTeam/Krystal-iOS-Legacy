//
//  TxSettingObject.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import BigInt

public enum GasSpeed {
    case slow
    case regular
    case fast
    case superFast
}

public struct TxSettingObject {
    public var basic: TxBasicSetting?
    public var advanced: TxAdvancedSetting?
    
    public static let `default`: TxSettingObject = .init(basic: .init(), advanced: nil)
    
    public var gasLimit: BigInt {
        if let advance = advanced {
            return advance.gasLimit
        }
        return basic?.gasLimit ?? TransactionConstants.defaultGasLimit
    }
    
}

public struct TxBasicSetting {
    public var gasLimit: BigInt = TransactionConstants.defaultGasLimit
    public var gasType: GasSpeed = .regular
}

public struct TxAdvancedSetting {
    public var gasLimit: BigInt
    public var maxFee: BigInt
    public var maxPriorityFee: BigInt
    public var nonce: Int
}
