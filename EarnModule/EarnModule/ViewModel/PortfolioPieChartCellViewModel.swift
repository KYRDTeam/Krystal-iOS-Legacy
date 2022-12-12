//
//  PortfolioPieChartCellViewModel.swift
//  EarnModule
//
//  Created by Com1 on 09/12/2022.
//

import UIKit
import BaseModule
import Services
import Utilities
import BigInt

class PortfolioPieChartCellViewModel: BaseViewModel {
    let earningBalances: [EarningBalance]
    let chainID: Int?
    
    var dataSource: [EarningBalance] {
        var earningBalanceData = earningBalances
        if let chainID = chainID {
            earningBalanceData = earningBalances.filter({ item in
                return item.chainID == chainID
            })
        }
        
        earningBalanceData = earningBalanceData.sorted(by: { firstObject, secondObject in
            let firstBalance = BigInt(firstObject.toUnderlyingToken.balance) ?? BigInt(0)
            let firstUsdValue = BigInt(firstObject.underlyingUsd * pow(10.0 , Double(firstObject.toUnderlyingToken.decimals))) * firstBalance / BigInt(pow(10.0 , Double(firstObject.toUnderlyingToken.decimals)))
            
            
            let secondBalance = BigInt(secondObject.toUnderlyingToken.balance) ?? BigInt(0)
            let secondUsdValue = BigInt(secondObject.underlyingUsd * pow(10.0 , Double(secondObject.toUnderlyingToken.decimals))) * secondBalance / BigInt(pow(10.0 , Double(secondObject.toUnderlyingToken.decimals)))
            return firstUsdValue > secondUsdValue
        })
        return earningBalanceData
    }
    
    var remainUSDValue: Double? {
        if dataSource.count > 5 {
            var total: Double = 0.0
            for index in 5..<dataSource.count {
                let earningBalance = dataSource[index]
                let toUnderlyingBalanceBigInt = BigInt(earningBalance.toUnderlyingToken.balance) ?? BigInt(0)
                let usdBigIntValue = BigInt(earningBalance.underlyingUsd * pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals))) * toUnderlyingBalanceBigInt / BigInt(pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals)))
                total += usdBigIntValue.doubleValue(decimal: earningBalance.toUnderlyingToken.decimals)
            }
            return total
        }
        return nil
    }
    
    var earningAssets: Double {
        var total: Double = 0.0
        var earningBalanceData = earningBalances
        if let chainID = chainID {
            earningBalanceData = earningBalances.filter({ item in
                return item.chainID == chainID
            })
        }
        for earningBalance in earningBalanceData {
            let toUnderlyingBalanceBigInt = BigInt(earningBalance.toUnderlyingToken.balance) ?? BigInt(0)
            let usdBigIntValue = BigInt(earningBalance.underlyingUsd * pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals))) * toUnderlyingBalanceBigInt / BigInt(pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals)))
            total += usdBigIntValue.doubleValue(decimal: earningBalance.toUnderlyingToken.decimals)
        }
        return total
    }
    
    var earningAssetsString: String {
        return StringFormatter.usdString(value: earningAssets)
    }
    
    var apyDouble: Double {
        var total: Double = 0.0
        var earningBalanceData = earningBalances
        if let chainID = chainID {
            earningBalanceData = earningBalances.filter({ item in
                return item.chainID == chainID
            })
        }
        for earningBalance in earningBalanceData {
            let toUnderlyingBalanceBigInt = BigInt(earningBalance.toUnderlyingToken.balance) ?? BigInt(0)
            let usdBigIntValue = BigInt(earningBalance.underlyingUsd * pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals))) * toUnderlyingBalanceBigInt / BigInt(pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals)))
            let usdDouble = usdBigIntValue.doubleValue(decimal: earningBalance.toUnderlyingToken.decimals)
            
            total += (usdDouble * earningBalance.apy) / 100
        }
        return total / earningAssets
    }
    
    var apyString: String {
        return StringFormatter.percentString(value: apyDouble)
    }
    
    var annualYieldString: String {
        return StringFormatter.usdString(value: earningAssets * apyDouble)
    }
    
    var dailyEarningString: String {
        if earningAssets * apyDouble / 365 < 0.01 {
            return "< $0.01"
        }
        return StringFormatter.usdString(value: earningAssets * apyDouble / 365)
    }
    
    var cellHeight: CGFloat {
        if dataSource.count <= 2 {
            return 300
        } else if dataSource.count <= 4 {
            return 350
        }
        return 390
    }
    
    init(earningBalances: [EarningBalance], chainID: Int?) {
        self.earningBalances = earningBalances
        self.chainID = chainID
    }
}
