//
//  ConfirmBridgeViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 30/05/2022.
//

import UIKit
import BigInt
import Utilities
import BaseModule

struct ConfirmBridgeViewModel {
  let fromChain: ChainType?
  let fromValue: String
  let fromAddress: String
  let toChain: ChainType?
  let toValue: String
  let toAddress: String
  let bridgeFee: String
  let token: TokenObject
  var gasPrice: BigInt
  var gasLimit: BigInt
  let signTransaction: SignTransaction?
  let eip1559Transaction: EIP1559Transaction?
  
  init(fromChain: ChainType?,
       fromValue: String,
       fromAddress: String,
       toChain: ChainType?,
       toValue: String,
       toAddress: String,
       bridgeFee: String,
       token: TokenObject,
       gasPrice: BigInt,
       gasLimit: BigInt,
       signTransaction: SignTransaction?,
       eip1559Transaction: EIP1559Transaction?) {
    self.fromChain = fromChain
    self.fromValue = fromValue
    self.fromAddress = fromAddress
    self.toChain = toChain
    self.toValue = toValue
    self.bridgeFee = bridgeFee
    self.toAddress = toAddress
    self.token = token
    self.gasPrice = gasPrice
    self.gasLimit = gasLimit
    self.signTransaction = signTransaction
    self.eip1559Transaction = eip1559Transaction
  }
  
  var feeUSDString: String {
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.fee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 18).displayRate()
    return "~ \(valueString) USD"
  }
  
  var transactionGasPriceString: String {
    let gasPriceText = gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 5
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }
  
  var feeString: String {
    return self.fee.displayRate(decimals: 18)
  }
  
  var fee: BigInt {
    return self.gasPrice * self.gasLimit
  }
}

protocol ConfirmBridgeViewControllerDelegate: class {
  func didConfirm(_ controller: ConfirmBridgeViewController, signTransaction: SignTransaction, internalHistoryTransaction: InternalHistoryTransaction)
  func didConfirm(_ controller: ConfirmBridgeViewController, eip1559Tx: EIP1559Transaction, internalHistoryTransaction: InternalHistoryTransaction)
  func openGasPriceSelect()
}

class ConfirmBridgeViewController: InAppBrowsingViewController {

  @IBOutlet weak var fromAddressLabel: UILabel!
  @IBOutlet weak var fromTokenValueLabel: UILabel!
  @IBOutlet weak var fromChainLabel: UILabel!
  @IBOutlet weak var fromIcon: UIImageView!
  @IBOutlet weak var toIcon: UIImageView!
  @IBOutlet weak var toChainLabel: UILabel!
  @IBOutlet weak var toChainTokenValueLabel: UILabel!
  @IBOutlet weak var toAddressLabel: UILabel!
  @IBOutlet weak var gasDescriptionLabel: UILabel!
  @IBOutlet weak var usdValueLabel: UILabel!
  @IBOutlet weak var estimatedTimeLabel: UIButton!
  @IBOutlet weak var feeValueLabel: UILabel!
  @IBOutlet weak var tapOutsideView: UIView!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var bridgeFeeLabel: UILabel!
  @IBOutlet weak var fromValueWidth: NSLayoutConstraint!
  @IBOutlet weak var toValueWidth: NSLayoutConstraint!
  fileprivate var viewModel: ConfirmBridgeViewModel
  weak var delegate: ConfirmBridgeViewControllerDelegate?
  let transitor = TransitionDelegate()
  
  init(viewModel: ConfirmBridgeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ConfirmBridgeViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.tapOutsideView.addGestureRecognizer(tapGesture)
    self.fromIcon.image = self.viewModel.fromChain?.chainIcon()
    self.fromChainLabel.text = self.viewModel.fromChain?.chainName()
    let fromString = "- " + self.viewModel.fromValue
    self.fromTokenValueLabel.text = fromString
    self.fromValueWidth.constant = fromString.width(withConstrainedHeight: 21, font: UIFont.Kyber.regular(with: 18))
    self.fromAddressLabel.text = "\(self.viewModel.fromAddress.prefix(8))...\(self.viewModel.fromAddress.suffix(4))"
    self.toIcon.image = self.viewModel.toChain?.chainIcon()
    self.toChainLabel.text = self.viewModel.toChain?.chainName()
    let toString = "+ " + self.viewModel.toValue
    self.toChainTokenValueLabel.text = toString
    self.toValueWidth.constant = toString.width(withConstrainedHeight: 21, font: UIFont.Kyber.regular(with: 18))
    self.toAddressLabel.text = "\(self.viewModel.toAddress.prefix(8))...\(self.viewModel.toAddress.suffix(4))"
    self.feeValueLabel.text = self.viewModel.feeString + " \(self.viewModel.fromChain?.quoteToken() ?? "")"
    self.bridgeFeeLabel.text = self.viewModel.bridgeFee
    self.usdValueLabel.text = self.viewModel.feeUSDString
    self.gasDescriptionLabel.text = self.viewModel.transactionGasPriceString
    MixPanelManager.track("bridge_confirm_pop_up_open", properties: ["screenid": "bridge_confirm_pop_up"])
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }
  
  func coordinatorDidUpdateFee(gasPrice: BigInt, gasLimit: BigInt) {
    self.viewModel.gasPrice = gasPrice
    self.viewModel.gasLimit = gasLimit
    self.feeValueLabel.text = self.viewModel.feeString + " \(self.viewModel.fromChain?.quoteToken() ?? "")"
    self.usdValueLabel.text = self.viewModel.feeUSDString
    self.gasDescriptionLabel.text = self.viewModel.transactionGasPriceString
  }
  
  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func editButtonTapped(_ sender: Any) {
    self.delegate?.openGasPriceSelect()
  }
  
  @IBAction func confirmButtonTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
    if let unwrap = self.viewModel.signTransaction, let fromChain = viewModel.fromChain, let toChain = viewModel.toChain {
      let internalHistory = InternalHistoryTransaction(type: .bridge, state: .pending, fromSymbol: self.viewModel.token.symbol, toSymbol: self.viewModel.token.symbol, transactionDescription: "", transactionDetailDescription: "", transactionObj: unwrap.toSignTransactionObject(), eip1559Tx: nil)
        let extra = BridgeTrackingExtraData(srcChainId:  "\(self.viewModel.fromChain?.getChainId() ?? 0)",
                                srcToken: self.viewModel.token.symbol,
                                srcTokenAmount: self.viewModel.fromValue,
                                destChainId: "\(self.viewModel.toChain?.getChainId() ?? 0)",
                                destToken: self.viewModel.token.symbol,
                                destTokenAmount:  self.viewModel.toValue,
                                bridgeFee: self.viewModel.feeString,
                                router: "")
        internalHistory.trackingExtraData = extra
      
      self.delegate?.didConfirm(self, signTransaction: unwrap, internalHistoryTransaction: internalHistory)
    }
    
    MixPanelManager.track("kbridge_confirm", properties: ["screenid": "bridge_confirm_pop_up"])
  }
}

extension ConfirmBridgeViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 650
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
