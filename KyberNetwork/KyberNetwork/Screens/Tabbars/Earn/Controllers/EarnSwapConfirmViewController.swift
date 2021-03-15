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
  let transaction: SignTransaction
  let rawTransaction: TxObject
  
  var toAmountString: String {
    let amountString = self.toAmount.displayRate(decimals: self.toToken.decimals)
    return "\(amountString.prefix(15)) \(self.toToken.symbol)"
  }
  
  var fromAmountString: String {
    let amountString = self.fromAmount.displayRate(decimals: self.toToken.decimals)
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
    return "+" + String(format: "%.2f", (self.platform.distributionSupplyRate + self.platform.supplyRate) * 100.0) + "%"
  }
  
  var transactionFee: BigInt {
    return self.gasPrice * self.gasLimit
  }

  var feeETHString: String {
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) ETH"
  }
  
  var feeUSDString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.transactionFee / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.displayRate(decimals: 18)
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
  @IBOutlet weak var depositAPYBottomContraint: NSLayoutConstraint!
  @IBOutlet weak var distributionAPYContainerView: UIView!
  @IBOutlet weak var framingIconContainerView: UIView!
  @IBOutlet weak var sendButtonTopContraint: NSLayoutConstraint!
  @IBOutlet weak var distributeAPYValueLabel: UILabel!
  
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
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }
  
  fileprivate func setupUI() {
    self.confirmButton.rounded(radius: self.confirmButton.frame.size.height / 2)
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.confirmButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
    self.cancelButton.rounded(color: UIColor(red: 35, green: 167, blue: 181), width: 1, radius: self.cancelButton.frame.size.height / 2)
    self.toAmountLabel.text = self.viewModel.toAmountString
    self.fromAmountLabel.text = self.viewModel.fromAmountString
    
    self.platformNameLabel.text = self.viewModel.platform.name
    if self.viewModel.platform.isCompound {
      self.framingIconContainerView.isHidden = false
      self.sendButtonTopContraint.constant = 133
      self.compInfoMessageContainerView.isHidden = false
    } else {
      self.framingIconContainerView.isHidden = true
      self.sendButtonTopContraint.constant = 20
      self.compInfoMessageContainerView.isHidden = true
    }
    self.depositAPYValueLabel.text = self.viewModel.depositAPYString
    let distributeAPY = self.viewModel.distributionAPYString
    if distributeAPY.isEmpty {
      self.depositAPYBottomContraint.constant = 20
      self.distributionAPYContainerView.isHidden = true
    } else {
      self.depositAPYBottomContraint.constant = 45
      self.distributionAPYContainerView.isHidden = true
      self.distributeAPYValueLabel.text = self.viewModel.distributionAPYString
    }
    self.transactionFeeETHLabel.text = self.viewModel.feeETHString
    self.transactionFeeUSDLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
    self.netAPYValueLabel.text = self.viewModel.netAPYString
    
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func sendButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      let transactionHistory = InternalHistoryTransaction(type: .earn, state: .pending, fromSymbol: self.viewModel.toToken.symbol, toSymbol: self.viewModel.earnTokenSymbol, transactionDescription: "\(self.viewModel.toAmountString) -> \(self.viewModel.earnAmountString)", transactionDetailDescription: "")
      
      self.delegate?.earnConfirmViewController(self, didConfirm: self.viewModel.transaction, amount: self.viewModel.toAmountString, netAPY: self.viewModel.netAPYString, platform: self.viewModel.platform, historyTransaction: transactionHistory)
    }
  }
}

extension EarnSwapConfirmViewController: BottomPopUpAbstract {
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
