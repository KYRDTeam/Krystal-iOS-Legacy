// Copyright SIX DAY LLC. All rights reserved.

import UIKit



protocol KConfirmSwapViewControllerDelegate: class {
  func kConfirmSwapViewController(_ controller: KConfirmSwapViewController, confirm data: KNDraftExchangeTransaction, signTransaction: SignTransaction, internalHistoryTransaction: InternalHistoryTransaction)
  func kConfirmSwapViewController(_ controller: KConfirmSwapViewController, confirm data: KNDraftExchangeTransaction, eip1559Tx: EIP1559Transaction, internalHistoryTransaction: InternalHistoryTransaction)
  func kConfirmSwapViewControllerDidCancel(_ controller: KConfirmSwapViewController)
}

class KConfirmSwapViewController: KNBaseViewController {


  @IBOutlet weak var fromAmountLabel: UILabel!
  @IBOutlet weak var toAmountLabel: UILabel!

  @IBOutlet weak var equivalentUSDValueLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!

  @IBOutlet weak var expectedRateLabel: UILabel!
  @IBOutlet weak var minAcceptableRateValueButton: UIButton!
  @IBOutlet weak var minReceivedTitle: UILabel!

  @IBOutlet weak var transactionFeeETHLabel: UILabel!
  @IBOutlet weak var transactionFeeUSDLabel: UILabel!
  @IBOutlet weak var transactionGasPriceLabel: UILabel!
  @IBOutlet weak var warningETHBalImageView: UIImageView!
  @IBOutlet weak var warningETHBalanceLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var reserveRoutingMessageContainer: UIView!
  @IBOutlet weak var reserveRoutingMessageLabel: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var rateWarningLabel: UILabel!

  @IBOutlet weak var priceImpactValueLabel: UILabel!
  @IBOutlet weak var swapAnywayCheckBox: UIButton!
  @IBOutlet weak var swapAnywayContainerView: UIView!
  @IBOutlet weak var priceImpactTextLabel: UILabel!
  var isAccepted: Bool = true

  fileprivate var viewModel: KConfirmSwapViewModel
  weak var delegate: KConfirmSwapViewControllerDelegate?
  let transitor = TransitionDelegate()

  init(viewModel: KConfirmSwapViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KConfirmSwapViewController.className, bundle: nil)
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

  fileprivate func setupUI() {
    self.fromAmountLabel.text = self.viewModel.leftAmountString
    self.fromAmountLabel.addLetterSpacing()
    self.toAmountLabel.text = self.viewModel.rightAmountString
    self.toAmountLabel.addLetterSpacing()

    self.expectedRateLabel.text = self.viewModel.displayEstimatedRate
    self.expectedRateLabel.addLetterSpacing()
    self.minAcceptableRateValueButton.setTitle(self.viewModel.minReceiveAmount, for: .normal)
    self.minReceivedTitle.text = self.viewModel.minReceiveTitle
    self.minAcceptableRateValueButton.setTitleColor(
      self.viewModel.warningMinAcceptableRateMessage == nil ? UIColor(red: 245, green: 246, blue: 249) : UIColor(red: 250, green: 101, blue: 102),
      for: .normal
    )
    self.minAcceptableRateValueButton.isEnabled = self.viewModel.warningMinAcceptableRateMessage != nil
    self.minAcceptableRateValueButton.semanticContentAttribute = .forceRightToLeft
    self.minAcceptableRateValueButton.setImage(
      self.viewModel.warningMinAcceptableRateMessage == nil ? nil : UIImage(named: "info_red_icon"),
      for: .normal
    )

    self.transactionFeeETHLabel.text = self.viewModel.feeETHString
    self.transactionFeeETHLabel.addLetterSpacing()
    self.transactionFeeUSDLabel.text = self.viewModel.feeUSDString
    self.transactionFeeUSDLabel.addLetterSpacing()
    transactionGasPriceLabel.text = viewModel.transactionGasPriceString
    transactionGasPriceLabel.addLetterSpacing()

    self.confirmButton.rounded(radius: self.confirmButton.frame.size.height / 2)
    self.cancelButton.rounded(radius: self.cancelButton.frame.size.height / 2)
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
    self.transactionFeeTextLabel.text = "Maximum gas fee".toBeLocalised()
    self.transactionFeeTextLabel.addLetterSpacing()
    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount

    let warningBalShown = self.viewModel.warningETHBalanceShown
    self.warningETHBalImageView.isHidden = !warningBalShown
    self.warningETHBalanceLabel.text = self.viewModel.warningETHText

    self.reserveRoutingMessageContainer.isHidden = self.viewModel.hint == "" || self.viewModel.hint == "0x"

    self.reserveRoutingMessageLabel.text = self.viewModel.reverseRoutingText
    self.priceImpactTextLabel.text = self.viewModel.priceImpactText
    self.priceImpactValueLabel.text = self.viewModel.priceImpactValueText
    self.priceImpactValueLabel.textColor = self.viewModel.priceImpactValueTextColor
    self.reserveRoutingMessageContainer.isHidden = !self.viewModel.priceImpactText.isEmpty
    self.swapAnywayCheckBox.rounded(radius: 2)
    if self.viewModel.hasPriceImpact {
      self.isAccepted = false
      self.swapAnywayContainerView.isHidden = false
      self.updateUIPriceImpact()
    } else {
      self.swapAnywayContainerView.isHidden = true
    }

    self.view.layoutIfNeeded()
  }
  
  fileprivate func updateUIPriceImpact() {
    guard self.viewModel.hasPriceImpact else { return }
    if self.isAccepted {
      self.swapAnywayCheckBox.rounded(radius: 2)
      self.swapAnywayCheckBox.backgroundColor = UIColor(named: "buttonBackgroundColor")
      self.swapAnywayCheckBox.setImage(UIImage(named: "filter_check_icon"), for: .normal)
      self.confirmButton.isEnabled = true
      self.confirmButton.alpha = 1
    } else {
      self.swapAnywayCheckBox.rounded(color: UIColor.lightGray, width: 1, radius: 2)
      self.swapAnywayCheckBox.backgroundColor = UIColor.clear
      self.swapAnywayCheckBox.setImage(nil, for: .normal)
      self.confirmButton.isEnabled = false
      self.confirmButton.alpha = 0.5
    }
  }

  @IBAction func checkBoxTapped(_ sender: UIButton) {
    self.isAccepted = !isAccepted
    self.updateUIPriceImpact()
  }
  
  @IBAction func tapMinAcceptableRateValue(_ sender: Any?) {
    guard let message = self.viewModel.warningMinAcceptableRateMessage else { return }
    self.showTopBannerView(
      with: "",
      message: message,
      icon: UIImage(named: "info_red_icon"),
      time: 2.0
    )
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
    if let unwrap = self.viewModel.signTransaction {
      let internalHistory = InternalHistoryTransaction(type: .swap, state: .pending, fromSymbol: self.viewModel.transaction.from.symbol, toSymbol: self.viewModel.transaction.to.symbol, transactionDescription: "\(self.viewModel.leftAmountString) -> \(self.viewModel.rightAmountString)", transactionDetailDescription: self.viewModel.displayEstimatedRate, transactionObj: unwrap.toSignTransactionObject(), eip1559Tx: nil)
      internalHistory.transactionSuccessDescription = "\(self.viewModel.leftAmountString) -> \(self.viewModel.rightAmountString)"
      self.delegate?.kConfirmSwapViewController(self, confirm: self.viewModel.transaction, signTransaction: unwrap, internalHistoryTransaction: internalHistory)
    }
    if let unwrap = self.viewModel.eip1559Transaction {
      let internalHistory = InternalHistoryTransaction(type: .swap, state: .pending, fromSymbol: self.viewModel.transaction.from.symbol, toSymbol: self.viewModel.transaction.to.symbol, transactionDescription: "\(self.viewModel.leftAmountString) -> \(self.viewModel.rightAmountString)", transactionDetailDescription: self.viewModel.displayEstimatedRate, transactionObj: nil, eip1559Tx: unwrap)
      internalHistory.transactionSuccessDescription = "\(self.viewModel.leftAmountString) -> \(self.viewModel.rightAmountString)"
      
      self.delegate?.kConfirmSwapViewController(self, confirm: self.viewModel.transaction, eip1559Tx: unwrap, internalHistoryTransaction: internalHistory)
    }
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
    self.delegate?.kConfirmSwapViewControllerDidCancel(self)
  }

  @IBAction func helpButtonTapped(_ sender: UIButton) {
    var mes = ""
    if sender.tag == 1 {
      if self.viewModel.priceImpact == -1000 {
        mes = " Missing price impact. Please swap with caution."
      } else {
        mes = String(format: KNGeneralProvider.shared.priceAlertMessage.toBeLocalised(), self.viewModel.priceImpactValueText)
      }
    } else {
      mes = "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised()
    }
    self.showBottomBannerView(
      message: mes,
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 10
    )
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension KConfirmSwapViewController: BottomPopUpAbstract {
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
