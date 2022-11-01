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
    }
    
    func getEstimatedGasFee() -> String {
        let priorityFee: BigInt? = {
            if let basic = setting.basic {
                return getPriority(gasType: basic.gasType)
            } else {
                return setting.advanced?.maxPriorityFee
            }
        }()
        let gasLimit: BigInt = {
            if let advance = setting.advanced {
                return advance.gasLimit
            }
            return TransactionConstants.defaultGasLimit
        }()
        let fee = (AppDependencies.gasConfig.baseFee ?? .zero) + (priorityFee ?? .zero)
        return formatFeeStringFor(gasPrice: fee, gasLimit: gasLimit)
    }
    
    func getPriority(gasType: GasSpeed) -> BigInt? {
        switch gasType {
        case .slow:
            return AppDependencies.gasConfig.lowPriorityFee
        case .regular:
            return AppDependencies.gasConfig.standardPriorityFee
        case .fast:
            return AppDependencies.gasConfig.fastPriorityFee
        case .superFast:
            return AppDependencies.gasConfig.superFastPriorityFee
        }
    }
    
    func formatFeeStringFor(gasPrice: BigInt, gasLimit: BigInt) -> String {
        let feeString: String = NumberFormatUtils.gasFeeFormat(number: gasPrice * gasLimit)
        if let chain = ChainType.make(chainID: approval.chainId) {
            return "\(feeString) \(chain.customRPC().quoteToken)"
        } else {
            return ""
        }
    }
    
}
