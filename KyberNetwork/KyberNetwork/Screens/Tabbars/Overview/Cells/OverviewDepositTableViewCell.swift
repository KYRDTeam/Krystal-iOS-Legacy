//
//  OverviewDepositTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit
import BigInt

protocol OverviewDepositCellViewModel {
  var symbol: String { get }
  var displayBalance: String { get }
  var displayValue: String { get }
  var balanceBigInt: BigInt { get }
  var valueBigInt: BigInt { get }
  var currencyType: CurrencyMode { get set }
  func updateCurrencyType(_ type: CurrencyMode)
  var hideBalanceStatus: Bool { get set }
  var displayAPY: String { get }
  var logo: String { get }
}

class OverviewDepositLendingBalanceCellViewModel: OverviewDepositCellViewModel {
  var hideBalanceStatus: Bool = true
  func updateCurrencyType(_ type: CurrencyMode) {
    self.currencyType = type
  }

  var currencyType: CurrencyMode = .usd
  
  var symbol: String {
    return self.balance.symbol
  }
  
  var displayBalance: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let balanceString = self.balanceBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: 5)

    return "\(balanceString) \(self.balance.symbol) "
  }
  
  var displayValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let valueString = self.valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return !self.currencyType.symbol().isEmpty ? self.currencyType.symbol() + valueString : valueString + self.currencyType.suffixSymbol()
  }
  
  var displayAPY: String {
    let rateString = String(format: "%.2f", self.balance.supplyRate * 100)
    return "\(rateString)%".paddingString()
  }

  var balanceBigInt: BigInt {
    return BigInt(self.balance.supplyBalance) ?? BigInt(0)
  }
  
  var logo: String {
    return self.balance.logo
  }

  var valueBigInt: BigInt {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.balance.address) else { return BigInt(0) }
    return self.balanceBigInt * BigInt(tokenPrice.priceWithCurrency(currencyMode: self.currencyType) * pow(10.0, 18.0)) / BigInt(10).power(self.balance.decimals)
  }

  let balance: LendingBalance

  init(balance: LendingBalance) {
    self.balance = balance
  }
}

class OverviewDepositDistributionBalanceCellViewModel: OverviewDepositCellViewModel {
  var hideBalanceStatus: Bool = true
  func updateCurrencyType(_ type: CurrencyMode) {
    self.currencyType = type
  }
  
  var symbol: String {
    return self.balance.symbol
  }

  var displayBalance: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let balanceString = self.balanceBigInt.string(decimals: self.balance.decimal, minFractionDigits: 0, maxFractionDigits: 5)

    return "\(balanceString) \(self.balance.symbol)"
  }

  var displayValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let valueString = self.valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return !self.currencyType.symbol().isEmpty ? self.currencyType.symbol() + valueString : valueString + self.currencyType.suffixSymbol()
  }

  var displayAPY: String {
    return ""
  }
  
  var balanceBigInt: BigInt {
    return BigInt(self.balance.unclaimed) ?? BigInt(0)
  }
  
  var logo: String {
    return ""
  }
  
  var valueBigInt: BigInt {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.balance.address) else { return BigInt(0) }
    return self.balanceBigInt * BigInt(tokenPrice.priceWithCurrency(currencyMode: self.currencyType) * pow(10.0, 18.0)) / BigInt(10).power(self.balance.decimal)
  }
  
  var currencyType: CurrencyMode = .usd

  let balance: LendingDistributionBalance

  init(balance: LendingDistributionBalance) {
    self.balance = balance
  }
}

class OverviewDepositTableViewCell: UITableViewCell {
  static let kCellID: String = "OverviewDepositTableViewCell"
  static let kCellHeight: CGFloat = 48
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenBalanceInfoLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var tokenApyInfo: UILabel!
  @IBOutlet weak var chainTypeImageView: UIImageView!
  
  func updateCell(viewModel: OverviewDepositCellViewModel) {
    self.iconImageView.setImage(urlString: viewModel.logo, symbol: viewModel.symbol)
    self.tokenBalanceInfoLabel.text = viewModel.displayBalance
    self.valueLabel.text = viewModel.displayValue
    self.tokenApyInfo.text = viewModel.displayAPY
    self.tokenApyInfo.isHidden = viewModel.displayAPY.isEmpty
  }

  func updateCell(_ viewModel: OverviewMainCellViewModel) {
    self.iconImageView.setImage(urlString: viewModel.logo, symbol: viewModel.tokenSymbol)
    self.tokenBalanceInfoLabel.text = viewModel.displayTitle
    self.tokenApyInfo.text = viewModel.displaySubTitleDetail
    self.valueLabel.text = viewModel.displayAccessoryTitle
    self.tokenApyInfo.isHidden = viewModel.displaySubTitleDetail.isEmpty
    if case .supply(let bal) = viewModel.mode, let distributionBal = bal as? LendingDistributionBalance, let chain = distributionBal.chainType {
      self.chainTypeImageView.image = chain.chainIcon()
      self.chainTypeImageView.isHidden = false
    } else {
      self.chainTypeImageView.isHidden = true
    }
  }
}
