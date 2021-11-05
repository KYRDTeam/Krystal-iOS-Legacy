//
//  OvereviewSummaryCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/11/2021.
//

import UIKit

class OverviewSummaryCellViewModel {
  let currency: CurrencyMode
  let symbol: String
  let chainName: String
  let value: Double
  let percentage: Double
  
  var hideBalanceStatus: Bool = true
  var chainType: ChainType?

  init(dataModel: KNSummaryChainModel, currency: CurrencyMode) {
    self.currency = currency
    self.symbol = dataModel.chainName
    self.chainName = dataModel.chainName
    self.chainType = dataModel.chainType()
    self.percentage = dataModel.percentage
    if let unitValueModel = dataModel.quotes[currency.toString()] {
      self.value = unitValueModel.value
    } else {
      self.value = 0.0
    }
  }

  func balanceValue() -> String {
    guard !self.hideBalanceStatus else {
      return "********"
    }

    let currencyFormatter = StringFormatter()
    return self.currency.symbol() + currencyFormatter.currencyString(value: self.value, decimals: self.currency.decimalNumber())
  }
  
  func chainIconImage() -> UIImage {
    switch self.chainType {
    case .eth:
      return UIImage(named: "chain_eth_icon")!
    case .bsc:
      return UIImage(named: "chain_bsc_icon")!
    case .polygon:
      return UIImage(named: "chain_polygon_big_icon")!
    case .avalanche:
      return UIImage(named: "chain_avax_icon")!
    default:
      return UIImage(named: "default_token")!
    }
  }
}

class OverviewSummaryCell: UITableViewCell {
  static let kCellID: String = "OvereviewSummaryCell"
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
    self.chainNameLabel.text = viewModel.chainName
    self.chainValueLabel.text = viewModel.balanceValue()
    self.percentLabel.text = StringFormatter.percentString(value: viewModel.percentage)
  }

}
