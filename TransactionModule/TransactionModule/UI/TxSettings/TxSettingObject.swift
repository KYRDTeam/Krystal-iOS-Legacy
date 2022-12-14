//
//  TxSettingObject.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import BigInt
import BaseWallet
import Dependencies

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
    
    public func transactionFee(chain: ChainType) -> BigInt {
        if let basic = basic {
            return gasLimit * getGasPrice(gasType: basic.gasType, chain: chain)
          } else if let advance = advanced {
            return gasLimit * advance.maxFee
          }
        return BigInt(0)
    }
    
    func getGasPrice(gasType: GasSpeed, chain: ChainType) -> BigInt {
        switch gasType {
        case .slow:
            return AppDependencies.gasConfig.getLowGasPrice(chain: chain)
        case .regular:
            return AppDependencies.gasConfig.getStandardGasPrice(chain: chain)
        case .fast:
            return AppDependencies.gasConfig.getFastGasPrice(chain: chain)
        case .superFast:
            return AppDependencies.gasConfig.getSuperFastGasPrice(chain: chain)
        }
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
