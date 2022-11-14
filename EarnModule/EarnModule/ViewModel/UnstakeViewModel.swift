//
//  UnstakeViewModel.swift
//  EarnModule
//
//  Created by Com1 on 14/11/2022.
//

import UIKit
import Services
import BigInt
import Utilities

class UnstakeViewModel {
    let displayDepositedValue: String
    let ratio: BigInt
    let stakingTokenSymbol: String
    let toTokenSymbol: String
    let balance: BigInt
    let platform: Platform
    var unstakeValue: BigInt = BigInt(0)

    init(earningBalance: EarningBalance) {
        self.displayDepositedValue = (BigInt(earningBalance.stakingToken.balance)?.shortString(decimals: earningBalance.stakingToken.decimals) ?? "---") + " " + earningBalance.stakingToken.symbol
        self.ratio = BigInt(earningBalance.ratio)
        self.stakingTokenSymbol = earningBalance.stakingToken.symbol
        self.toTokenSymbol = earningBalance.toUnderlyingToken.symbol
        self.balance = BigInt(earningBalance.stakingToken.balance) ?? BigInt(0)
        self.platform = earningBalance.platform
    }
    
    
    func receivedValue() -> BigInt {
        return unstakeValue * self.ratio / BigInt(10).power(18)
    }
    
    func receivedValueString() -> String {
        return NumberFormatUtils.balanceFormat(value: receivedValue(), decimals: 18) + " " + toTokenSymbol
    }
    
    func receivedValueMaxString() -> String {
        let maxValue = balance * self.ratio / BigInt(10).power(18)
        return NumberFormatUtils.balanceFormat(value: maxValue, decimals: 18)
    }
    
    func showRateInfo() -> String {
        let ratioString = NumberFormatUtils.balanceFormat(value: ratio, decimals: 18)
        return "1 \(stakingTokenSymbol) = \(ratioString) \(toTokenSymbol)"
    }
    
    func timeForUnstakeString() -> String {
        let isAnkr = platform.name.lowercased() == "ANKR".lowercased()
        let isLido = platform.name.lowercased() == "LIDO".lowercased()
        
        var time = ""
        if toTokenSymbol.lowercased() == "AVAX".lowercased() && isAnkr {
            time = "4 weeks"
        } else if toTokenSymbol.lowercased() == "BNB".lowercased() && isAnkr {
            time = "7-14 days"
        } else if toTokenSymbol.lowercased() == "FTM".lowercased() && isAnkr {
            time = "35 days"
        } else if toTokenSymbol.lowercased() == "MATIC".lowercased() && isAnkr {
            time = "3-4 days"
        } else if toTokenSymbol.lowercased() == "SOL".lowercased() && isLido {
            time = "2-3 days"
        }
        
        return "You will receive your \(toTokenSymbol) in \(time)"
    }
    
}
