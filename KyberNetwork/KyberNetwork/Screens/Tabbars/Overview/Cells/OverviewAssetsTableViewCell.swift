//
//  OverviewAssetsTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit
import BigInt
import SwipeCellKit

class OverviewAssetsCellViewModel {
  let token: Token
  var currencyType: CurrencyType = .usd
  
  init(token: Token) {
    self.token = token
  }
  
  var displaySymbol: String {
    return self.token.symbol.uppercased()
  }

  var balanceBigInt: BigInt {
    return self.token.getBalanceBigInt()
  }
  
  var comparableBalanceBigInt: BigInt {
    return self.balanceBigInt * BigInt(10).power(18) / BigInt(10).power(self.token.decimals)
  }
  
  var displayTokenBalance: String {
    return self.balanceBigInt.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: min(self.token.decimals, 6))
  }

  var priceDouble: Double {
    return self.currencyType == .usd ? self.token.getTokenPrice().usd : self.token.getTokenPrice().eth
  }

  var displayPrice: String {
    let price = self.priceDouble
    return self.currencyType == .usd ? "$" + String(format: "%.2f", price) : String(format: "%.2f", price)
  }
  
  var valueBigInt: BigInt {
    let rateBigInt = BigInt(self.priceDouble * pow(10.0, 18.0))
    let valueBigInt = self.balanceBigInt * rateBigInt / BigInt(10).power(18)
    return valueBigInt
  }
  
  var diplayValue: String {
    let valueString = self.valueBigInt.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: min(self.token.decimals, 6))
    return self.currencyType == .usd ? "$" + valueString : valueString
  }

  var change24Double: Double {
    let change24 = self.currencyType == .usd ? self.token.getTokenPrice().usd24hChange : self.token.getTokenPrice().eth24hChange
    return change24
  }
  
  var displayChange24h: String {
    let change24 = self.change24Double
    return String(format: "%.2f", change24) + "%"
  }
  
  var displayChange24Color: UIColor {
    let change24 = self.change24Double
    return change24 > 0 ? UIColor.Kyber.SWGreen : UIColor.Kyber.SWRed
  }
}

class OverviewAssetsTableViewCell: SwipeTableViewCell {
  static let kCellID: String = "OverviewAssetsTableViewCell"
  static let kCellHeight: CGFloat = 60
  
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var change24Label: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  
  func updateCell(viewModel: OverviewAssetsCellViewModel) {
    self.tokenIconImageView.setSymbolImage(symbol: viewModel.token.symbol)
    self.symbolLabel.text = viewModel.displaySymbol
    self.balanceLabel.text = viewModel.displayTokenBalance
    self.priceLabel.text = viewModel.displayPrice
    self.change24Label.text = viewModel.displayChange24h
    self.change24Label.textColor = viewModel.displayChange24Color
    self.valueLabel.text = viewModel.diplayValue
  }
}
