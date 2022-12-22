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
    var amount: String
    var usdValue: String
    var isTokenChangePositive: Bool
    
    init(transfer: TxRecord.TokenTransfer) {
        let status = TokenVerifyStatus(value: transfer.token?.tag ?? "")
        tokenIconUrl = transfer.token?.logo
        verifyIcon = status.icon
        
        let amountSign = transfer.amount.starts(with: "-") ? "-" : "+"
        let absDoubleAmount = abs(Double(transfer.amount) ?? 0)
        isTokenChangePositive = amountSign == "+"
        
        var tokenSymbol = transfer.token?.symbol
        if tokenSymbol.isNilOrEmpty {
            tokenSymbol = "Unknown"
        }
        
        var decimals = transfer.token?.decimals
        if decimals == 0 {
            decimals = 18
        }
        
        amount = amountSign + NumberFormatUtils.amount(value: BigInt(absDoubleAmount), decimals: decimals ?? 18) + " " + (tokenSymbol ?? "")
        if transfer.historicalValueInUsd == 0 {
            usdValue = ""
        } else {
            usdValue = "$" + NumberFormatUtils.usdAmount(value: BigInt(abs(transfer.historicalValueInUsd) * pow(10, 18)), decimals: 18)
        }
    }
}
