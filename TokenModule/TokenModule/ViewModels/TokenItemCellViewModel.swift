//
//  TokenItemCellViewModel.swift
//  TokenModule
//
//  Created by Tung Nguyen on 17/02/2023.
//

import Foundation
import ChainModule
import BigInt
import Utilities

class TokenItemCellViewModel: Hashable {
    var name: String
    var iconUrl: String
    var tagIcon: UIImage
    var balanceValueString: String
    var balanceString: String
    let token: Token
    
    static func == (lhs: TokenItemCellViewModel, rhs: TokenItemCellViewModel) -> Bool {
        return lhs.name == rhs.name && lhs.iconUrl == rhs.iconUrl && lhs.tagIcon == rhs.tagIcon && lhs.balanceString == rhs.balanceString && lhs.balanceValueString == rhs.balanceValueString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(balanceValueString)
        hasher.combine(balanceString)
        hasher.combine(name)
    }
    
    init(token: Token, balance: BigInt, price: Double) {
        self.token = token
        self.name = token.name
        self.iconUrl = token.iconUrl
        self.tagIcon = UIImage()
        let formattedBalance = NumberFormatUtils.balanceFormat(value: balance, decimals: token.decimal)
        self.balanceString = "\(formattedBalance) \(token.symbol)"
        if price == 0 {
            self.balanceValueString = ""
        } else {
            let balanceValue = balance * BigInt(price * pow(10, 18))
            self.balanceValueString = "$" + NumberFormatUtils.usdValueFormat(value: balanceValue, decimals: token.decimal + 18)
        }
    }
    
}

extension Array where Element: Token {
    
    func toViewModels(walletAddress: String) -> [TokenItemCellViewModel] {
        let balanceDB = TokenBalanceDB.shared
        let priceDB = TokenPriceDB.shared
        return map { token in
            let balance = balanceDB.getBalance(tokenAddress: token.address, chainID: token.chainID, walletAddress: walletAddress)
            let price = priceDB.getPrice(tokenAddress: token.address, chainID: token.chainID)
            return TokenItemCellViewModel(token: token, balance: balance, price: price)
        }
    }
    
}
