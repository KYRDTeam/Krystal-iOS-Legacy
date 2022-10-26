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
        amountString = bigIntAmount > BigInt(10).power(24)
                                        ? Strings.unlimitedAllowance
                                        : NumberFormatUtils.amount(value: bigIntAmount, decimals: approval.decimals)
    }
    
}
