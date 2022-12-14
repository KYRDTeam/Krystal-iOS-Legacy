//
//  ApprovedTokenItemViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation
import UIKit
import Services
import BigInt

class ApprovedTokenItemViewModel {
    var symbol: String?
    var tokenIcon: String?
    var chainIcon: UIImage?
    var tokenName: String?
    var isVerified: Bool
    var spenderValue: String?
    var amountString: String?
    let approval: Approval
    var showChainIcon: Bool
    
    let minUnlimitedApprovalAmount: BigInt = BigInt(10).power(9)
    
    init(approval: Approval, showChainIcon: Bool) {
        self.approval = approval
        symbol = approval.symbol
        tokenIcon = approval.logo
        chainIcon = ChainType.make(chainID: approval.chainId)?.squareIcon()
        tokenName = approval.name
        isVerified = approval.isVerified
        if approval.spenderName.isNilOrEmpty {
            spenderValue = approval.spenderAddress?.shortTypeAddress
        } else {
            spenderValue = approval.spenderName
        }
        let bigIntAmount = BigInt(approval.amount ?? "0") ?? .zero
        amountString = bigIntAmount > BigInt(10).power(approval.decimals) * minUnlimitedApprovalAmount
                                        ? Strings.unlimitedAllowance
                                        : NumberFormatUtils.amount(value: bigIntAmount, decimals: approval.decimals)
        self.showChainIcon = showChainIcon
    }
}
