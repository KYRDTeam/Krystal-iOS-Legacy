//
//  SwapTransactionSettings.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/08/2022.
//

import Foundation
import BigInt
import TransactionModule

struct SwapTransactionSettings {
    var slippage: Double
    var basic: BasicTransactionSettings?
    var advanced: AdvancedTransactionSettings?
    var expertModeOn: Bool = false
    
    static func getDefaultSettings() -> SwapTransactionSettings {
        let slippage = UserDefaults.standard.double(forKey: Constants.slippageRateSaveKey)
        return SwapTransactionSettings(
            slippage: slippage > 0 ? slippage : 0.5,
            basic: BasicTransactionSettings(gasPriceType: .medium),
            advanced: nil,
            expertModeOn: UserDefaults.standard.bool(forKey: Constants.expertModeSaveKey)
        )
    }
    
    func toCommonTxSettings() -> TxSettingObject {
        var txBasic: TxBasicSetting?
        var txAdvanced: TxAdvancedSetting?
        
        if let basic = basic {
            txBasic = .init(gasLimit: basic.gasPriceType.getGasValue(), gasType: .regular)
        }
        
        if let advanced = advanced {
            txAdvanced = .init(gasLimit: advanced.gasLimit, maxFee: advanced.maxFee, maxPriorityFee: advanced.maxPriorityFee, nonce: advanced.nonce)
        }
        
        return .init(basic: txBasic, advanced: txAdvanced)
    }
    
}

struct AdvancedTransactionSettings {
    var gasLimit: BigInt
    var maxFee: BigInt
    var maxPriorityFee: BigInt
    var nonce: Int
}

struct BasicTransactionSettings {
    var gasPriceType: KNSelectedGasPriceType
}
