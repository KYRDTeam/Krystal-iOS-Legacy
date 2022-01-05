//
//  DappBrowerTransactionConfirmPopup.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 05/01/2022.
//

import UIKit
import BigInt

struct  DappBrowerTransactionConfirmViewModel {
  let transaction: SignTransactionObject
  let url: String
  let onSign: (() -> Void)
  let onCancel: (() -> Void)
  
  var displayFromAddress: String {
    return self.transaction.from
  }
  
  var valueBigInt: BigInt {
    return BigInt(self.transaction.value) ?? BigInt(0)
  }
  
  var gasPriceBigInt: BigInt {
    return BigInt(self.transaction.gasPrice) ?? BigInt(0)
  }
  
  var gasLimitBigInt: BigInt {
    return BigInt(self.transaction.gasLimit) ?? BigInt(0)
  }
  
  var displayValue: String {
    let prefix = self.valueBigInt.isZero ? "" : "-"
    return prefix + "\(self.valueBigInt.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken)"
  }
  
  var displayValueUSD: String {
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.valueBigInt * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    
    let valueString: String = usd.displayRate(decimals: 18)
    return "≈ $\(valueString)"
  }
  
  var transactionFeeETHString: String {
    let fee: BigInt = {
      return self.gasPriceBigInt * self.gasLimitBigInt
    }()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  var transactionFeeUSDString: String {
    let fee: BigInt = {
      return self.gasPriceBigInt * self.gasLimitBigInt
    }()

    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = fee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }
  
  var transactionGasPriceString: String {
    let gasPriceText = self.gasPriceBigInt.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: self.gasLimitBigInt, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }
  
  var imageIconURL: String {
    return "https://www.google.com/s2/favicons?sz=128&domain=\(self.url)/"
  }
}

class DappBrowerTransactionConfirmPopup: KNBaseViewController {
  @IBOutlet weak var siteIconImageView: UIImageView!
  @IBOutlet weak var siteURLLabel: UILabel!
  @IBOutlet weak var fromAddressLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var equivalentValueLabel: UILabel!
  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  private let viewModel: DappBrowerTransactionConfirmViewModel
  
  let transitor = TransitionDelegate()
  
  init(viewModel: DappBrowerTransactionConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: DappBrowerTransactionConfirmPopup.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupUI()
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onCancel()
    }
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onSign()
    }
  }
  
  @IBAction func transactionFeeHelpButtonTapped(_ sender: UIButton) {
    
    
  }
  
  private func setupUI() {
    self.fromAddressLabel.text = self.viewModel.displayFromAddress
    self.valueLabel.text = self.viewModel.displayValue
    self.equivalentValueLabel.text = self.viewModel.displayValueUSD
    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    self.gasPriceTextLabel.text = self.viewModel.transactionGasPriceString
    self.siteURLLabel.text = self.viewModel.url
    UIImage.loadImageIconWithCache(viewModel.imageIconURL) { image in
      self.siteIconImageView.image = image
    }
    self.confirmButton.rounded(radius: 16)
    self.cancelButton.rounded(radius: 16)
  }
}

extension DappBrowerTransactionConfirmPopup: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 600
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
