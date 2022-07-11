//
//  PortfolioAssetCellViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 11/07/2022.
//

import Foundation
import BigInt

class PortfolioAssetCellViewModel {
  var token: Token
  var price: Double
  var hideBalance: Bool
  let balanceStorage = BalanceStorage.shared
  
  init(token: Token, price: Double, currencyMode: CurrencyType, hideBalance: Bool) {
    self.token = token
    self.price = price
    self.hideBalance = hideBalance
  }
  
  var symbol: String {
    return token.symbol
  }
  
  var displaySymbol: String {
    return token.symbol.uppercased()
  }
  
  private var balance: BigInt {
    let balance = BalanceStorage.shared.balanceForAddress(token.address)
    return BigInt(balance?.balance ?? "") ?? BigInt(0)
  }
}
