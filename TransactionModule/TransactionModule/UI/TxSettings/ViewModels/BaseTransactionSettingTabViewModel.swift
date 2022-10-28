//
//  BaseTransactionSettingTabViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import Dependencies
import BigInt
import BaseWallet
import AppState
import Utilities

class BaseTransactionSettingTabViewModel {
    
    var gasConfig: GasConfig
    var gasLimit: BigInt = BigInt(120_000)
    var chain: ChainType
    
    init(gasConfig: GasConfig, chain: ChainType) {
        self.gasConfig = gasConfig
        self.chain = chain
    }
    
    func getPriority(gasType: GasType) -> BigInt? {
        switch gasType {
        case .slow:
            return gasConfig.lowPriorityFee
        case .regular:
            return gasConfig.standardPriorityFee
        case .fast:
            return gasConfig.fastPriorityFee
        case .superFast:
            return gasConfig.superFastPriorityFee
        }
    }
    
    func getGasPrice(gasType: GasType) -> BigInt {
        switch gasType {
        case .slow:
            return gasConfig.lowGas
        case .regular:
            return gasConfig.standardGas
        case .fast:
            return gasConfig.fastGas
        case .superFast:
            return gasConfig.superFastGas
        }
    }
    
    func getEstimatedGasFee(setting: TxSettingObject) -> String {
        let priorityFee: BigInt? = {
            if let basic = setting.basic {
                return getPriority(gasType: basic.gasType)
            } else {
                return setting.advanced?.maxPriorityFee
            }
        }()
        let fee = (gasConfig.baseFee ?? .zero) + (priorityFee ?? .zero)
        return formatFeeStringFor(gasPrice: fee, gasLimit: gasLimit)
    }
    
    func getMaxFeeString(setting: TxSettingObject) -> String {
        let gasPrice: BigInt = {
            if let basic = setting.basic {
                return getGasPrice(gasType: basic.gasType)
            } else {
                return setting.advanced?.maxFee ?? .zero
            }
        }()
        let gasLimit: BigInt = {
            if setting.basic != nil {
                return self.gasLimit
            } else {
                return setting.advanced?.gasLimit ?? .zero
            }
        }()
        if let usdRate = AppDependencies.priceStorage.getUsdRate() {
            let fee: BigInt = gasPrice * gasLimit
            let usdAmt = fee * BigInt(usdRate * pow(10.0, 18.0)) / BigInt(10).power(18)
            let valueEth = NumberFormatUtils.gasFee(value: fee) + " \(chain.customRPC().quoteToken)"
            let value = NumberFormatUtils.gasFee(value: usdAmt)
            return "Max fee: \(valueEth) ~ $\(value) USD"
        }
        return ""
    }
    
    func formatFeeStringFor(gasPrice: BigInt, gasLimit: BigInt) -> String {
        let feeString: String = NumberFormatUtils.gasFeeFormat(number: gasPrice * gasLimit)
        return "~ \(feeString) \(chain.customRPC().quoteToken)"
    }
    
}
