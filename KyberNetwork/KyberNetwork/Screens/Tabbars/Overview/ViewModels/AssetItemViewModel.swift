//
//  AssetItemViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 15/02/2023.
//

import Foundation
import ChainModule

class AssetItemViewModel {
    var icon: String
    var symbol: String
    var balance: String
    
    init(token: ChainModule.Token, balance: ChainModule.TokenBalance) {
        self.icon = token.iconUrl
        self.symbol = token.symbol
        self.balance = NumberFormatUtils.balanceFormat(value: balance.balance, decimals: token.decimal)
    }
}
