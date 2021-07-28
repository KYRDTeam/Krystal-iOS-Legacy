//
//  ChooseRateTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 23/07/2021.
//

import UIKit
import BigInt

class ChooseRateCellViewModel {
  let rate: Rate
  let from: TokenData
  let to: TokenData
  let gasPrice: BigInt
  var completionHandler: (Rate) -> Void = { _ in }
  var isDeposit = false
  
  init(rate: Rate, from: TokenData, to: TokenData, gasPrice: BigInt) {
    self.rate = rate
    self.from = from
    self.to = to
    self.gasPrice = gasPrice
  }
  
  var displayPlatform: String {
    return rate.platform
  }
  
  var displayRate: String {
    if let rate = BigInt(self.rate.rate) {
      return rate.isZero ? "---" : "1 \(self.from.symbol) = \(rate.displayRate(decimals: 18)) \(self.to.symbol)"
    } else {
      return "---"
    }
  }
  
  var displayMaxGasFee: String {
    let estGas = BigInt(self.rate.estimatedGas)
    let rate = KNTrackerRateStorage.shared.getETHPrice()
    let rateUSDDouble = rate?.usd ?? 0
    let fee = estGas * gasPrice
    let rateBigInt = BigInt(rateUSDDouble * pow(10.0, 18.0))
    let feeUSD = fee * rateBigInt / BigInt(10).power(18)
    return "\(fee.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken) ~ $\(feeUSD.displayRate(decimals: 18))"
  }
}

class ChooseRateTableViewCell: UITableViewCell {
  static let kCellID: String = "ChooseRateTableViewCell"
  static let kCellHeight: CGFloat = 115
  
  @IBOutlet weak var platformNameLabel: UILabel!
  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var maxGasFeeLabel: UILabel!
  @IBOutlet weak var gasFeeTitleLabel: UILabel!
  
  var cellModel: ChooseRateCellViewModel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateCell(_ viewModel: ChooseRateCellViewModel) {
    self.platformNameLabel.text = viewModel.displayPlatform
    self.rateLabel.text = viewModel.displayRate
    self.maxGasFeeLabel.text = viewModel.displayMaxGasFee
    self.gasFeeTitleLabel.isHidden = viewModel.isDeposit
    self.maxGasFeeLabel.isHidden = viewModel.isDeposit
    self.cellModel = viewModel
  }
  
  @IBAction func cellTapped(_ sender: UIButton) {
    if let notNil = self.cellModel {
      notNil.completionHandler(notNil.rate)
    }
  }
}
