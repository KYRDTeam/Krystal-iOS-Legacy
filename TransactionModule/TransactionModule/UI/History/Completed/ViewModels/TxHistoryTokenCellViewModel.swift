//
//  TxHistoryTokenCellViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import Services
import UIKit
import BigInt
import Utilities

struct TxHistoryTokenCellViewModel {
    var tokenIconUrl: String?
    var verifyIcon: UIImage?
    var amountString: String
    var usdValue: String
    var isTokenChangePositive: Bool
    
    let minUnlimitedApprovalAmount: BigInt = BigInt(10).power(9)
    
    init(token: TokenInfo, amount: BigInt, usdValueInUsd: Double, isApproval: Bool) {
        let status = TokenVerifyStatus(value: token.tag ?? "")
        tokenIconUrl = token.logo
        verifyIcon = status.icon
        
        let absAmount = abs(amount)
        let amountSign = isApproval ? "" : (amount < 0 ? "-" : "+")
        isTokenChangePositive = isApproval ? false : amount > 0
        
        var tokenSymbol = token.symbol
        if tokenSymbol.isEmpty {
            tokenSymbol = "Unknown"
        }
        
        var decimals = token.decimals
        if decimals == 0 {
            decimals = 18
        }
        
        amountString = absAmount > BigInt(10).power(token.decimals) * minUnlimitedApprovalAmount
                        ? "Unlimited \(tokenSymbol)"
                        : amountSign + NumberFormatUtils.amount(value: absAmount, decimals: decimals) + " " + tokenSymbol
        
        if usdValueInUsd == 0 {
            usdValue = ""
        } else {
            let usdAmountString = NumberFormatUtils.usdAmount(value: BigInt(abs(usdValueInUsd) * pow(10, 18)), decimals: 18)
            if usdAmountString == "0" {
                usdValue = NumberFormatUtils.lessThanMinUsdAmountString()
            } else {
                usdValue = "$" + usdAmountString
            }
        }
    }
    
}
