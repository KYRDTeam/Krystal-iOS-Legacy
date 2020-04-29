// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

enum KNTransactionDetailsViewEvent {
  case back
  case openEtherScan
  case openEnjinXScan
}

protocol KNTransactionDetailsViewControllerDelegate: class {
  func transactionDetailsViewController(_ controller: KNTransactionDetailsViewController, run event: KNTransactionDetailsViewEvent)
}

class KNTransactionDetailsViewController: KNBaseViewController {

  weak var delegate: KNTransactionDetailsViewControllerDelegate?
  fileprivate var viewModel: KNTransactionDetailsViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navigationTitleLabel: UILabel!

  @IBOutlet weak var txTypeLabel: UILabel!
  @IBOutlet weak var leftAmountTextLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var rightAmountTextLabel: UILabel!

  @IBOutlet weak var exchangeRateLabel: UILabel!
  @IBOutlet weak var rateTextLabel: UILabel!

  @IBOutlet var feeTopPaddingToSeparatorViewConstraint: NSLayoutConstraint!
  @IBOutlet var feeTopPaddingToRateLabelConstraint: NSLayoutConstraint!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UILabel!

  @IBOutlet weak var addressTextLabel: UILabel!
  @IBOutlet weak var addressValueLabel: UILabel!

  @IBOutlet var txHashTopPaddingToAddressLabelConstraint: NSLayoutConstraint!
  @IBOutlet var txHashTopPaddingToFeeLabelConstraint: NSLayoutConstraint!

  @IBOutlet weak var txHashLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var viewOnTextLabel: UILabel!

  init(viewModel: KNTransactionDetailsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTransactionDetailsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.updateUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    self.navigationTitleLabel.text = NSLocalizedString("transaction.details", value: "Transaction Details", comment: "")
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    let addressTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.addressLabelTapped(_:)))
    self.addressValueLabel.addGestureRecognizer(addressTapGesture)

    self.feeTextLabel.text = NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")

    let txHashTapGes = UITapGestureRecognizer(target: self, action: #selector(self.txHashTapped(_:)))
    self.txHashLabel.addGestureRecognizer(txHashTapGes)
    self.viewOnTextLabel.text = NSLocalizedString("view.on", value: "View on", comment: "")
  }

  fileprivate func updateUI() {
    self.txTypeLabel.text = self.viewModel.displayTxTypeString

    self.feeValueLabel.text = self.viewModel.displayFee

    let amountText = self.viewModel.displayedAmountString
    if self.viewModel.isSwap {
      let amounts = amountText.components(separatedBy: "➞")

      if amounts.count == 2 {
        self.amountLabel.text = "➞"
        self.leftAmountTextLabel.text = amounts[0]
        self.rightAmountTextLabel.text = amounts[1]
        self.leftAmountTextLabel.isHidden = false
        self.rightAmountTextLabel.isHidden = false
      } else {
        self.amountLabel.text = amountText
        self.leftAmountTextLabel.isHidden = true
        self.rightAmountTextLabel.isHidden = true
      }

      self.rateTextLabel.text = self.viewModel.displayRateTextString
      self.exchangeRateLabel.text = self.viewModel.displayExchangeRate
      self.addressTextLabel.isHidden = true
      self.addressValueLabel.isHidden = true

      self.rateTextLabel.isHidden = false
      self.exchangeRateLabel.isHidden = false

      self.feeTopPaddingToRateLabelConstraint.constant = 8.0
      self.feeTopPaddingToRateLabelConstraint.isActive = true
      self.feeTopPaddingToSeparatorViewConstraint.isActive = false

      self.txHashTopPaddingToFeeLabelConstraint.isActive = true
      self.txHashTopPaddingToFeeLabelConstraint.constant = 16.0
      self.txHashTopPaddingToAddressLabelConstraint.isActive = false

    } else {
      self.amountLabel.text = amountText
      self.leftAmountTextLabel.isHidden = true
      self.rightAmountTextLabel.isHidden = true

      self.rateTextLabel.isHidden = true
      self.exchangeRateLabel.isHidden = true

      self.addressTextLabel.isHidden = false
      self.addressValueLabel.isHidden = false

      self.addressTextLabel.text = self.viewModel.addressTextDisplay
      self.addressValueLabel.attributedText = self.viewModel.addressAttributedString()

      self.feeTopPaddingToRateLabelConstraint.isActive = false
      self.feeTopPaddingToSeparatorViewConstraint.isActive = true
      self.feeTopPaddingToSeparatorViewConstraint.constant = 28

      self.txHashTopPaddingToFeeLabelConstraint.isActive = false
      self.txHashTopPaddingToAddressLabelConstraint.isActive = true
      self.txHashTopPaddingToAddressLabelConstraint.constant = 16.0
    }

    self.txHashLabel.attributedText = self.viewModel.txHashAttributedString()
    self.dateLabel.text = self.viewModel.dateString()

    self.view.updateConstraintsIfNeeded()
    self.view.layoutIfNeeded()
  }

  @objc func addressLabelTapped(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transaction_details", customAttributes: ["action": "copy_from_address"])
    if self.viewModel.isSent {
      self.copy(text: self.viewModel.transaction?.to ?? "")
    } else {
      self.copy(text: self.viewModel.transaction?.from ?? "")
    }
  }

  @objc func txHashTapped(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transaction_details", customAttributes: ["action": "copy_tx_hash"])
    self.copy(text: self.viewModel.transaction?.id ?? "")
  }

  fileprivate func copy(text: String) {
    UIPasteboard.general.string = text

    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }

  func coordinator(update transaction: Transaction, currentWallet: KNWalletObject) {
    self.viewModel.update(transaction: transaction, currentWallet: currentWallet)
    self.updateUI()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.transactionDetailsViewController(self, run: .back)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.transactionDetailsViewController(self, run: .back)
    }
  }

  @IBAction func viewOnEtherscanButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transaction_details", customAttributes: ["action": "open_ether_scan"])
    self.delegate?.transactionDetailsViewController(self, run: .openEtherScan)
  }

  @IBAction func viewOnEnjinXButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transaction_details", customAttributes: ["action": "open_kyber_enjin_scan"])
    self.delegate?.transactionDetailsViewController(self, run: .openEnjinXScan)
  }
}
