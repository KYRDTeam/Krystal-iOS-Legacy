//
//  OvereviewSummaryCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/11/2021.
//

import UIKit
import BigInt

class OverviewSummaryCellViewModel {
  var currency: CurrencyMode
  let percentage: Double
  let value: Double
  var hideBalanceStatus: Bool = true
  var chainType: ChainType?
  var isDefaultValue: Bool = false

  init(dataModel: KNSummaryChainModel, currency: CurrencyMode) {
    self.currency = currency
    self.chainType = dataModel.chainType()
    self.percentage = dataModel.percentage
    if let unitValueModel = dataModel.quotes[currency.toString()] {
      self.value = unitValueModel.value
    } else {
      self.isDefaultValue = true
      self.value = 0.0
    }
  }

  func balanceValue() -> String {
    guard !self.isDefaultValue else {
      return "--"
    }
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let currencyFormatter = StringFormatter()
    let hideAndDeleteBigInt = KNSupportedTokenStorage.shared.getHideAndDeleteTokensBalanceUSD(self.currency, chainType: self.chainType ?? .eth)
    let hideAndDeleteValue = hideAndDeleteBigInt.doubleUSDValue(currencyDecimal: self.currency.decimalNumber())
    let chainBalanceValue = self.value - hideAndDeleteValue

    return self.currency.symbol() + NumberFormatUtils.valueFormat(value: chainBalanceValue.amountBigInt(decimals: 18) ?? BigInt(0), decimals: 18, currencyMode: self.currency) + self.currency.suffixSymbol()
    
    
  }

  func percentString() -> String {
    guard !self.isDefaultValue else {
      return "--"
    }
    guard !self.hideBalanceStatus else {
      return ""
    }
    return StringFormatter.percentString(value: self.percentage)
  }

  func chainIconImage() -> UIImage {
    guard let chainType = self.chainType else {
      return UIImage(named: "default_token")!
    }
    return chainType.chainIcon()!
  }

  func chainName() -> String {
    guard let chainType = self.chainType else {
      return "Unsupported"
    }
    return chainType.chainName()
  }
}

class OverviewSummaryCell: UITableViewCell {
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainValueLabel: UILabel!
  @IBOutlet weak var chainNameLabel: UILabel!
  @IBOutlet weak var percentLabel: UILabel!
  @IBOutlet weak var backgroundContainView: UIView!
  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundContainView.rounded(radius: 16)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }

  func updateCell(_ viewModel: OverviewSummaryCellViewModel) {
    self.chainIcon.image = viewModel.chainIconImage()
    self.chainNameLabel.text = viewModel.chainName()
    self.chainValueLabel.text = viewModel.balanceValue()
    self.percentLabel.text = viewModel.percentString()
  }

}
