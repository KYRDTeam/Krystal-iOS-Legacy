//
//  RevokeConfirmViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 26/10/2022.
//

import Foundation
import Services
import UIKit
import BigInt
import TransactionModule
import Dependencies
import Utilities

class RevokeConfirmViewModel {
    var contract: String?
    var symbol: String?
    var tokenIcon: String?
    var chainIcon: UIImage?
    var tokenName: String?
    var isVerified: Bool
    var spenderAddress: String?
    var amountString: String?
    let approval: Approval
    var setting: TxSettingObject = .default
    var chain: ChainType?
    
    init(approval: Approval) {
        self.approval = approval
        contract = approval.tokenAddress
        symbol = approval.symbol
        tokenIcon = approval.logo
        chainIcon = ChainType.make(chainID: approval.chainId)?.squareIcon()
        tokenName = approval.name
        isVerified = approval.isVerified
        spenderAddress = approval.spenderAddress
        let bigIntAmount = BigInt(approval.amount ?? "0") ?? .zero
        amountString = bigIntAmount > BigInt(10).power(approval.decimals + 9)
                                        ? Strings.unlimitedAllowance
                                        : NumberFormatUtils.amount(value: bigIntAmount, decimals: approval.decimals)
        chain = ChainType.make(chainID: approval.chainId)
    }
    
    var maxFee: BigInt {
        if let advance = setting.advanced {
            return advance.maxFee
        } else if let basic = setting.basic {
            return getGasPrice(gasType: basic.gasType)
        }
        return .zero
    }
    
    var maxFeeTokenAmountString: String {
        guard let chain = chain else {
            return ""
        }
        let fee: BigInt = maxFee * setting.gasLimit
        let valueEth = NumberFormatUtils.gasFee(value: fee) + " \(chain.customRPC().quoteToken)"
        return valueEth
    }
    
    var maxFeeTokenUSDString: String {
        if let usdRate = AppDependencies.priceStorage.getUsdRate() {
            let fee: BigInt = maxFee * setting.gasLimit
            let usdAmt = fee * BigInt(usdRate * pow(10.0, 18.0)) / BigInt(10).power(18)
            let value = NumberFormatUtils.gasFee(value: usdAmt)
            return "≈ \(value) USD"
        }
        return ""
    }
    
    var maxGasFeeFomular: String {
        let gasPriceText = maxFee.shortString(
          units: .gwei,
          maxFractionDigits: 5
        )
        let gasLimitText = EtherNumberFormatter.short.string(from: setting.gasLimit, decimals: 0)
        return String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    }
    
//    func getEstimatedGasFee() -> String {
//        guard let chain = chain else {
//            return ""
//        }
//
//        let priorityFee: BigInt? = {
//            if let basic = setting.basic {
//                return getPriority(gasType: basic.gasType)
//            } else {
//                return setting.advanced?.maxPriorityFee
//            }
//        }()
//        let gasLimit: BigInt = {
//            if let advance = setting.advanced {
//                return advance.gasLimit
//            }
//            return TransactionConstants.defaultGasLimit
//        }()
//        let fee = (AppDependencies.gasConfig.getBaseFee(chain: chain) ?? .zero) + (priorityFee ?? .zero)
//        return formatFeeStringFor(gasPrice: fee, gasLimit: gasLimit)
//    }
//    
    func getGasPrice(gasType: GasSpeed) -> BigInt {
        guard let chain = chain else {
            return .zero
        }
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
    
    func getPriority(gasType: GasSpeed) -> BigInt? {
        guard let chain = chain else {
            return nil
        }
        switch gasType {
        case .slow:
            return AppDependencies.gasConfig.getLowPriorityFee(chain: chain)
        case .regular:
            return AppDependencies.gasConfig.getStandardPriorityFee(chain: chain)
        case .fast:
            return AppDependencies.gasConfig.getFastPriorityFee(chain: chain)
        case .superFast:
            return AppDependencies.gasConfig.getSuperFastPriorityFee(chain: chain)
        }
    }
    
    func formatFeeStringFor(gasPrice: BigInt, gasLimit: BigInt) -> String {
        guard let chain = chain else {
            return ""
        }
        let feeString: String = NumberFormatUtils.gasFeeFormat(number: gasPrice * gasLimit)
        return "\(feeString) \(chain.customRPC().quoteToken)"
    }
    
}
