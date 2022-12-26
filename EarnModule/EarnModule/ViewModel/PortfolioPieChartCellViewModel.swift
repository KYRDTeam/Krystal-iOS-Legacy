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

class PieChartModel {
    let chainId: Int
    let symbol: String
    let logo: String
    var balance: Double
    var usd: Double
    
    init(chainId: Int, symbol: String, logo: String, balance: Double, usd: Double) {
        self.chainId = chainId
        self.symbol = symbol
        self.logo = logo
        self.balance = balance
        self.usd = usd
    }
    
    func titleString(totalValue: Double) -> String {
        var toUnderlyingBalanceString = symbol + " " + StringFormatter.percentString(value: usd / totalValue)
        return toUnderlyingBalanceString
    }
    
    func usdDetailString() -> String {
        return usd < 0.01 ? "< $0.01" : StringFormatter.usdString(value: usd)
    }
}

class PortfolioPieChartCellViewModel: BaseViewModel {
    let earningBalances: [EarningBalance]
    let chainID: Int?
    
    var dataSource: [PieChartModel] {
        var earningBalanceData: [PieChartModel]  = []
        
        earningBalances.forEach { earningBalance in
            var isContaint = false
            for model in earningBalanceData {
                if model.chainId == earningBalance.chainID, model.symbol == earningBalance.toUnderlyingToken.symbol {
                    isContaint = true
                    model.balance += earningBalance.balanceValue()
                    model.usd += earningBalance.usdValue()
                }
            }
            
            if !isContaint {
                let balance = earningBalance.balanceValue()
                let usd = earningBalance.usdValue()
                let pieChartModel = PieChartModel(chainId: earningBalance.chainID, symbol: earningBalance.toUnderlyingToken.symbol, logo: earningBalance.toUnderlyingToken.logo, balance: balance, usd: usd)
                earningBalanceData.append(pieChartModel)
            }
        }
        
        if let chainID = chainID {
            earningBalanceData = earningBalanceData.filter({ $0.chainId == chainID })
        }
        
        earningBalanceData = earningBalanceData.sorted(by: { $0.usd > $1.usd })
        return earningBalanceData
    }
    
    var remainUSDValue: Double? {
        if dataSource.count > 5 {
            var total: Double = 0.0
            for index in 5..<dataSource.count {
                let model = dataSource[index]
                total += model.usd
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
            total += earningBalance.usdValue()
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
            total += (earningBalance.usdValue() * (earningBalance.apy + earningBalance.rewardApy) ) / 100
        }
        return total / earningAssets
    }
    
    var apyString: String {
        return StringFormatter.percentString(value: apyDouble)
    }
    
    var annualYieldString: String {
        if earningAssets * apyDouble < 0.01 {
            return "< $0.01"
        }
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
