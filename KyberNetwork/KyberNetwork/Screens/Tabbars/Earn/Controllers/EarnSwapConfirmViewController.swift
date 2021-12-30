//
//  EarnSwapConfirmViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/5/21.
//

import UIKit
import BigInt

struct EarnSwapConfirmViewModel {
  let platform: LendingPlatformData
  let fromToken: TokenData
  let fromAmount: BigInt
  let toToken: TokenData
  let toAmount: BigInt
  let gasPrice: BigInt
  let gasLimit: BigInt
  let transaction: SignTransaction?
  let eip1559Transaction: EIP1559Transaction?
  let rawTransaction: TxObject
  let minReceiveAmount: String
  let minReceiveTitle: String
  let priceImpact: Double
  
  var toAmountString: String {
    let amountString = self.toAmount.displayRate(decimals: self.toToken.decimals)
    return "\(amountString.prefix(15)) \(self.toToken.symbol)"
  }

  var fromAmountString: String {
    let amountString = self.fromAmount.displayRate(decimals: self.fromToken.decimals)
    return "\(amountString.prefix(15)) \(self.fromToken.symbol)"
  }
  
  var earnTokenSymbol: String {
    return self.platform.isCompound ? "c\(self.toToken.symbol)" : "a\(self.toToken.symbol)"
  }

  var earnAmountString: String {
    let amountString = self.toAmount.displayRate(decimals: self.toToken.decimals)
    return "\(amountString.prefix(15)) \(self.earnTokenSymbol)"
  }

  var depositAPYString: String {
    if self.platform.supplyRate == 0 {
      return ""
    } else {
      return String(format: "%.2f", self.platform.supplyRate * 100.0) + "%"
    }
  }

  var distributionAPYString: String {
    if self.platform.distributionSupplyRate == 0 {
      return ""
    } else {
      return String(format: "%.2f", self.platform.distributionSupplyRate * 100.0) + "%"
    }
  }

  var netAPYString: String {
    return String(format: "%.2f", (self.platform.distributionSupplyRate + self.platform.supplyRate) * 100.0) + "%"
  }
  
  var transactionFee: BigInt {
    return self.gasPrice * self.gasLimit
  }

  var feeETHString: String {
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) \(KNGeneralProvider.shared.quoteToken)"
  }

  var feeUSDString: String {
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.transactionFee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var transactionGasPriceString: String {
    let gasPriceText = self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: self.gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }

  var usdValueBigInt: BigInt {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.toToken.address) else { return BigInt(0) }
    let usd = self.toAmount * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.toToken.decimals)
    return usd
  }
  
  var fromUsdValueBigInt: BigInt {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.fromToken.address) else { return BigInt(0) }
    let usd = self.fromAmount * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.fromToken.decimals)
    return usd
  }

  var displayUSDValue: String {
    let value = self.usdValueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: DecimalNumber.usd)
    if let doubleValue = Double(value), doubleValue < 0.01 {
      return ""
    }
    return "≈ \(value) USD"
  }
  
  var fromDisplayUSDValue: String {
    let value = self.fromUsdValueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: DecimalNumber.usd)
    if let doubleValue = Double(value), doubleValue < 0.01 {
      return ""
    }
    return "≈ \(value) USD"
  }

  var displayCompInfo: String {
    let apy = String(format: "%.6f", self.platform.distributionSupplyRate * 100.0)
    let symbol = KNGeneralProvider.shared.currentChain == .bsc ? "XVS" : "COMP" 
    return "You will automatically earn \(symbol) token (\(apy)% APY) for interacting with \(self.platform.name) (supply or borrow).\n\nOnce redeemed, \(symbol) token can be swapped to any token."
  }

  var priceImpactValueText: String {
    guard self.priceImpact != -1000.0 else { return "---" }
    let displayPercent = "\(self.priceImpact)".prefix(6)
    return "\(displayPercent)%"
  }
  
  var priceImpactHintText: String {
    var message = ""
    if self.priceImpact != -1000 {
      message = String(format: KNGeneralProvider.shared.priceAlertMessage.toBeLocalised(), self.priceImpactValueText)
    } else {
      message = " Missing price impact. Please swap with caution."
    }
    return message
  }

  var priceImpactValueTextColor: UIColor? {
    guard self.priceImpact != -1000.0 else { return UIColor(named: "normalTextColor") }
    let change = self.priceImpact
    if change <= -5.0 {
      return UIColor(named: "textRedColor")
    } else if change <= -2.0 {
      return UIColor(named: "warningColor")
    } else {
      return UIColor(named: "textWhiteColor")
    }
  }

  var priceImpactText: String {
    guard self.priceImpact != -1000 else { return " Missing price impact. Please swap with caution." }
    return self.priceImpact > -5 ? "" : "Price impact is high. You may want to reduce your swap amount for a better rate."
  }

  var hasPriceImpact: Bool {
    return self.priceImpact <= -5
  }

  var needConfirm: Bool {
    return self.priceImpact <= -20
  }
}

class EarnSwapConfirmViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var fromAmountLabel: UILabel!
  @IBOutlet weak var toAmountLabel: UILabel!
  @IBOutlet weak var platformNameLabel: UILabel!
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var platformIconImageView: UIImageView!
  @IBOutlet weak var depositAPYValueLabel: UILabel!
  @IBOutlet weak var netAPYValueLabel: UILabel!
  @IBOutlet weak var transactionFeeETHLabel: UILabel!
  @IBOutlet weak var transactionFeeUSDLabel: UILabel!
  @IBOutlet weak var transactionGasPriceLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var compInfoMessageContainerView: UIView!
  @IBOutlet weak var distributionAPYContainerView: UIView!
  @IBOutlet weak var framingIconContainerView: UIView!
  @IBOutlet weak var sendButtonTopContraint: NSLayoutConstraint!
  @IBOutlet weak var distributeAPYValueLabel: UILabel!
  @IBOutlet weak var usdValueLabel: UILabel!
  @IBOutlet weak var fromUSDValueLabel: UILabel!
  @IBOutlet weak var compInfoLabel: UILabel!
  @IBOutlet weak var minimumReceivedTitleLabel: UILabel!
  @IBOutlet weak var minimumReceivedLabel: UILabel!
  @IBOutlet weak var priceImpactLabel: UILabel!
  @IBOutlet weak var priceImpaceWarningLabel: UILabel!
  @IBOutlet weak var swapAnywayContainerView: UIView!
  @IBOutlet weak var swapAnywayBtn: UIButton!
  @IBOutlet weak var topBackgroundView: UIView!
  var isAccepted: Bool = true
  let transitor = TransitionDelegate()
  let viewModel: EarnSwapConfirmViewModel
  weak var delegate: EarnConfirmViewControllerDelegate?
  
  init(viewModel: EarnSwapConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnSwapConfirmViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }

  fileprivate func setupUI() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.topBackgroundView.addGestureRecognizer(tapGesture)
    self.confirmButton.rounded(radius: 16)
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
    self.cancelButton.rounded(radius: 16)
    self.toAmountLabel.text = self.viewModel.toAmountString
    self.fromAmountLabel.text = self.viewModel.fromAmountString
    self.platformNameLabel.text = self.viewModel.platform.name
    if self.viewModel.platform.isCompound {
      self.framingIconContainerView.isHidden = false
      self.compInfoLabel.text = self.viewModel.displayCompInfo
      self.compInfoMessageContainerView.isHidden = false
    } else {
      self.framingIconContainerView.isHidden = true
      self.compInfoMessageContainerView.isHidden = true
    }
    self.depositAPYValueLabel.text = self.viewModel.depositAPYString
    let distributeAPY = self.viewModel.distributionAPYString
    if distributeAPY.isEmpty {
      self.distributionAPYContainerView.isHidden = true
    } else {
      self.distributionAPYContainerView.isHidden = false
      self.distributeAPYValueLabel.text = self.viewModel.distributionAPYString
    }
    self.transactionFeeETHLabel.text = self.viewModel.feeETHString
    self.transactionFeeUSDLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
    self.netAPYValueLabel.text = self.viewModel.netAPYString
    self.usdValueLabel.text = self.viewModel.displayUSDValue
    self.fromUSDValueLabel.text = self.viewModel.fromDisplayUSDValue
    self.platformIconImageView.image = KNGeneralProvider.shared.chainIconImage
    self.tokenIconImageView.setSymbolImage(symbol: self.viewModel.toToken.symbol)
    self.minimumReceivedLabel.text = self.viewModel.minReceiveAmount
    self.minimumReceivedTitleLabel.text = self.viewModel.minReceiveTitle
    self.priceImpactLabel.text = self.viewModel.priceImpactValueText
    self.priceImpactLabel.textColor = self.viewModel.priceImpactValueTextColor
    self.priceImpaceWarningLabel.text = self.viewModel.priceImpactText
    self.swapAnywayBtn.rounded(radius: 2)

    if self.viewModel.hasPriceImpact {
      self.isAccepted = false
      self.priceImpaceWarningLabel.isHidden = false
      self.framingIconContainerView.isHidden = true
      self.compInfoMessageContainerView.isHidden = true
      self.sendButtonTopContraint.constant = self.viewModel.needConfirm ? 150 : 100
      self.updateUIPriceImpact()
    } else {
      self.priceImpaceWarningLabel.isHidden = true
      self.sendButtonTopContraint.constant = self.viewModel.platform.isCompound ? 200 : 20
    }
    
    self.swapAnywayContainerView.isHidden = !self.viewModel.needConfirm
  }
  
  fileprivate func updateUIPriceImpact() {
    guard self.viewModel.needConfirm else { return }
    if self.isAccepted {
      self.swapAnywayBtn.rounded(radius: 2)
      self.swapAnywayBtn.backgroundColor = UIColor(named: "buttonBackgroundColor")
      self.swapAnywayBtn.setImage(UIImage(named: "filter_check_icon"), for: .normal)
      self.confirmButton.isEnabled = true
      self.confirmButton.alpha = 1
    } else {
      self.swapAnywayBtn.rounded(color: UIColor.lightGray, width: 1, radius: 2)
      self.swapAnywayBtn.backgroundColor = UIColor.clear
      self.swapAnywayBtn.setImage(nil, for: .normal)
      self.confirmButton.isEnabled = false
      self.confirmButton.alpha = 0.5
    }
  }

  @IBAction func checkBoxTapped(_ sender: UIButton) {
    self.isAccepted = !isAccepted
    self.updateUIPriceImpact()
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func sendButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      let transactionHistory = InternalHistoryTransaction(type: .earn, state: .pending, fromSymbol: self.viewModel.toToken.symbol, toSymbol: self.viewModel.earnTokenSymbol, transactionDescription: "\(self.viewModel.toAmountString) -> \(self.viewModel.earnAmountString)", transactionDetailDescription: "", transactionObj: self.viewModel.transaction?.toSignTransactionObject(), eip1559Tx: self.viewModel.eip1559Transaction)
      transactionHistory.transactionSuccessDescription = "\(self.viewModel.earnAmountString) with \(self.viewModel.netAPYString) APY"
      let earnTokenString = self.viewModel.platform.isCompound ? self.viewModel.platform.compondPrefix + self.viewModel.toToken.symbol : "a" + self.viewModel.toToken.symbol
      transactionHistory.earnTransactionSuccessDescription = "You’ve received \(earnTokenString) token because you supplied \(self.viewModel.toToken.symbol) in \(self.viewModel.platform.name). Simply by holding \(earnTokenString) token, you will earn interest."
      self.delegate?.earnConfirmViewController(self, didConfirm: self.viewModel.transaction, eip1559Transaction: self.viewModel.eip1559Transaction, amount: self.viewModel.toAmountString, netAPY: self.viewModel.netAPYString, platform: self.viewModel.platform, historyTransaction: transactionHistory)
    }
  }

  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }

  @IBAction func priceImpactHelpButtonTapped(_ sender: Any) {
    guard !self.viewModel.priceImpactValueText.isEmpty else { return }
    self.showBottomBannerView(
      message: self.viewModel.priceImpactHintText,
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
  @IBAction func apyHelpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "Positive APY mean you will receive interest and negative means you will pay interest.".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
}

extension EarnSwapConfirmViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return UIScreen.main.bounds.size.height * 0.85
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
