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
    var chain: ChainType
    var setting: TxSettingObject
    var remoteGasLimit: BigInt = TransactionConstants.defaultGasLimit
    
    init(settings: TxSettingObject, gasConfig: GasConfig, chain: ChainType) {
        self.setting = settings
        self.gasConfig = gasConfig
        self.chain = chain
    }
    
    var gasLimit: BigInt {
        if let advance = setting.advanced {
            return advance.gasLimit
        }
        return setting.basic?.gasLimit ?? remoteGasLimit
    }
    
    var priorityFee: BigInt {
        if let advance = setting.advanced {
            return advance.maxPriorityFee
        } else if let basic = setting.basic {
            return getPriority(gasType: basic.gasType) ?? .zero
        }
        return .zero
    }
    
    var maxFee: BigInt {
        if let advance = setting.advanced {
            return advance.maxFee
        } else if let basic = setting.basic {
            return getGasPrice(gasType: basic.gasType)
        }
        return .zero
    }
    
    var nonce: Int {
        if let advanced = setting.advanced {
            return advanced.nonce
        }
        return AppDependencies.nonceStorage.currentNonce(chain: chain, address: AppState.shared.currentAddress.addressString)
    }
    
    func getPriority(gasType: GasSpeed) -> BigInt? {
        switch gasType {
        case .slow:
            return gasConfig.getLowPriorityFee(chain: chain)
        case .regular:
            return gasConfig.getStandardPriorityFee(chain: chain)
        case .fast:
            return gasConfig.getFastPriorityFee(chain: chain)
        case .superFast:
            return gasConfig.getSuperFastPriorityFee(chain: chain)
        }
    }
    
    func getGasPrice(gasType: GasSpeed) -> BigInt {
        switch gasType {
        case .slow:
            return gasConfig.getLowGasPrice(chain: chain)
        case .regular:
            return gasConfig.getStandardGasPrice(chain: chain)
        case .fast:
            return gasConfig.getFastGasPrice(chain: chain)
        case .superFast:
            return gasConfig.getSuperFastGasPrice(chain: chain)
        }
    }
    
    func getEstimatedGasFee() -> String {
        let priorityFee: BigInt? = {
            if let basic = setting.basic {
                return getPriority(gasType: basic.gasType)
            } else {
                return setting.advanced?.maxPriorityFee
            }
        }()
        let fee = (gasConfig.getBaseFee(chain: chain) ?? .zero) + (priorityFee ?? .zero)
        return formatFeeStringFor(gasPrice: fee, gasLimit: gasLimit)
    }
    
    func getMaxFeeString() -> String {
        if let usdRate = AppDependencies.priceStorage.getQuoteUsdRate(chain: chain) {
            let fee: BigInt = maxFee * gasLimit
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
