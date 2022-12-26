//
//  OverviewLiquidityPoolCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/10/2021.
//

import UIKit
import BigInt

class OverviewLiquidityPoolViewModel {
  let currency: CurrencyMode
  let pairTokens: [LPTokenModel]
  var hideBalanceStatus: Bool = true
  var chainName: String = ""
  var chainId: Int = KNGeneralProvider.shared.currentChain.getChainId()
  var chainLogo: String = ""
  init(currency: CurrencyMode, pairToken: [LPTokenModel]) {
    self.currency = currency
    self.pairTokens = pairToken
  }

  func firstTokenSymbol() -> String {
    guard !pairTokens.isEmpty else {
      return ""
    }
    return pairTokens[0].token.symbol
  }

  func secondTokenSymbol() -> String {
    guard pairTokens.count > 1 else {
      return ""
    }
    return pairTokens[1].token.symbol
  }
  
  func firstTokenLogo() -> String {
    guard !pairTokens.isEmpty else {
      return ""
    }
    return pairTokens[0].token.logo
  }

  func secondTokenLogo() -> String {
    guard pairTokens.count > 1 else {
      return ""
    }
    return pairTokens[1].token.logo
  }

  func firstTokenValue() -> String {
    guard !self.hideBalanceStatus else {
      return "********" + " " + firstTokenSymbol()
    }
    guard !pairTokens.isEmpty else {
      return ""
    }
    let tokenModel = pairTokens[0]
    
    return NumberFormatUtils.balanceFormat(value: tokenModel.getBalanceBigInt(), decimals: tokenModel.token.decimals) + " " + firstTokenSymbol()
  }
  
  func secondTokenValue() -> String {
    guard !self.hideBalanceStatus else {
      return "********" + " " + secondTokenSymbol()
    }
    guard pairTokens.count > 1 else {
      return ""
    }
    let tokenModel = pairTokens[1]
    
    return NumberFormatUtils.balanceFormat(value: tokenModel.getBalanceBigInt(), decimals: tokenModel.token.decimals) + " " + secondTokenSymbol()
  }
  
  func balanceValue() -> String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    var total = 0.0
    for tokenModel in pairTokens {
      total += tokenModel.getTokenValue(self.currency)
    }
    let currencyFormatter = StringFormatter()
    let valueString = currencyFormatter.currencyString(value: total, decimals: self.currency.decimalNumber())
    return !self.currency.symbol().isEmpty ? self.currency.symbol() + valueString : valueString + self.currency.suffixSymbol()
  }
}

class OverviewLiquidityPoolCell: UITableViewCell {
  static let kCellHeight: CGFloat = 85
  @IBOutlet weak var cellBackgroundView: UIView!
  @IBOutlet weak var firstTokenIcon: UIImageView!
  @IBOutlet weak var secondTokenIcon: UIImageView!
  @IBOutlet weak var firstTokenValueLabel: UILabel!
  @IBOutlet weak var secondTokenValueLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!

  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }

  func updateCell(_ viewModel: OverviewLiquidityPoolViewModel) {
    if viewModel.firstTokenLogo().isEmpty {
      self.firstTokenIcon.setSymbolImage(symbol: viewModel.firstTokenSymbol())
    } else {
      self.firstTokenIcon.setImage(with: viewModel.firstTokenLogo(), placeholder: UIImage(named: "default_token")!)
    }
  
    if viewModel.secondTokenLogo().isEmpty {
      self.secondTokenIcon.setSymbolImage(symbol: viewModel.secondTokenSymbol())
    } else {
      self.secondTokenIcon.setImage(with: viewModel.secondTokenLogo(), placeholder: UIImage(named: "default_token")!)
    }
    
    self.firstTokenValueLabel.text = viewModel.firstTokenValue()
    self.secondTokenValueLabel.text = viewModel.secondTokenValue()
    self.balanceLabel.text = viewModel.balanceValue()
  }
}
