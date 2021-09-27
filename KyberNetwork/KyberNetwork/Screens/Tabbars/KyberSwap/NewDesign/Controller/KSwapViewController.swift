// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Result
import Moya
import Kingfisher
//swiftlint:disable file_length

enum KSwapViewEvent {
  case searchToken(from: TokenObject, to: TokenObject, isSource: Bool)
  case confirmSwap(data: KNDraftExchangeTransaction, tx: SignTransaction, hasRateWarning: Bool, platform: String, rawTransaction: TxObject, minReceiveDest: BigInt)
  case showQRCode
  case quickTutorial(step: Int, pointsAndRadius: [(CGPoint, CGFloat)])
  case openGasPriceSelect(gasLimit: BigInt, selectType: KNSelectedGasPriceType, pair: String, minRatePercent: Double)
  case updateRate(rate: Double)
  case openHistory
  case openWalletsList
  case getAllRates(from: TokenObject, to: TokenObject, amount: BigInt, focusSrc: Bool)
  case openChooseRate(from: TokenObject, to: TokenObject, rates: [Rate], gasPrice: BigInt)
  case checkAllowance(token: TokenObject)
  case sendApprove(token: TokenObject, remain: BigInt)
  case getExpectedRate(from: TokenObject, to: TokenObject, srcAmount: BigInt, hint: String)
  case getLatestNonce
  case buildTx(rawTx: RawSwapTransaction)
  case signAndSendTx(tx: SignTransaction)
  case getGasLimit(from: TokenObject, to: TokenObject, srcAmount: BigInt, rawTx: RawSwapTransaction)
  case getRefPrice(from: TokenObject, to: TokenObject)

//  static public func == (left: KSwapViewEvent, right: KSwapViewEvent) -> Bool {
//    switch (left, right) {
//    case let (.getGasLimit(fromL, toL, amountL, hintL), .getGasLimit(fromR, toR, amountR, hintR)):
//      return fromL == fromR && toL == toR && amountL == amountR && hintL == hintR
//    default:
//      return false //Not implement
//    }
//  }
}

protocol KSwapViewControllerDelegate: class {
  func kSwapViewController(_ controller: KSwapViewController, run event: KSwapViewEvent)
}

//swiftlint:disable type_body_length
class KSwapViewController: KNBaseViewController {

  fileprivate var isViewSetup: Bool = false
  fileprivate var isErrorMessageEnabled: Bool = false

  fileprivate var viewModel: KSwapViewModel
  weak var delegate: KSwapViewControllerDelegate?

  @IBOutlet weak var scrollContainerView: UIScrollView!

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var fromTokenButton: UIButton!

  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var toTokenButton: UIButton!

  @IBOutlet weak var fromAmountTextField: UITextField!
  @IBOutlet weak var equivalentUSDValueLabel: UILabel!
  @IBOutlet weak var toAmountTextField: UITextField!

  @IBOutlet weak var exchangeRateLabel: UILabel!

  @IBOutlet weak var bottomPaddingConstraintForScrollView: NSLayoutConstraint!

  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var walletsListButton: UIButton!
  @IBOutlet weak var gasFeeLabel: UILabel!
  @IBOutlet weak var slippageLabel: UILabel!
  @IBOutlet weak var changeRateButton: UIButton!
  @IBOutlet weak var approveButtonLeftPaddingContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonRightPaddingContaint: NSLayoutConstraint!
  @IBOutlet weak var approveButton: UIButton!
  @IBOutlet weak var approveButtonEqualWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var rateWarningLabel: UILabel!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var currentChainIcon: UIImageView!
  @IBOutlet weak var minReceivedAmount: UILabel!
  @IBOutlet weak var rateTimerView: SRCountdownTimer!
  @IBOutlet weak var minReceivedAmountTitleLabel: UILabel!
  
  
//  fileprivate var estRateTimer: Timer?
  fileprivate var estGasLimitTimer: Timer?
  fileprivate var previousCallEvent: KSwapViewEvent?
  fileprivate var previousCallTimeStamp: TimeInterval = 0
  var keyboardTimer: Timer?

  init(viewModel: KSwapViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KSwapViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.viewModel.resetDefaultTokensPair()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
      if self.viewModel.approvingToken == nil {
        self.updateAllowance()
      }
    }
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.updateUISwitchChain()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    KNCrashlyticsUtil.logCustomEvent(withName: "krystal_open_swap_view", customAttributes: nil)
    self.isErrorMessageEnabled = true
    // start update est rate
//    self.estRateTimer?.invalidate()
    self.updateAllRates()
    self.updateAllowance()
//    self.estRateTimer = Timer.scheduledTimer(
//      withTimeInterval: KNLoadingInterval.seconds30,
//      repeats: true,
//      block: { [weak self] _ in
//        guard let `self` = self else { return }
//        self.updateAllRates()
//      }
//    )

    // start update est gas limit
    self.estGasLimitTimer?.invalidate()
    self.updateEstimatedGasLimit()
    self.estGasLimitTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds60,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.updateEstimatedGasLimit()
      }
    )

    self.updateExchangeRateField()
    self.updateRefPrice()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isErrorMessageEnabled = false
    self.view.endEditing(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
//    self.estRateTimer?.invalidate()
//    self.estRateTimer = nil
    self.estGasLimitTimer?.invalidate()
    self.estGasLimitTimer = nil
  }

  fileprivate func setupUI() {
    self.walletsListButton.setTitle(self.viewModel.wallet.getWalletObject()?.name ?? "---", for: .normal)
    self.bottomPaddingConstraintForScrollView.constant = self.bottomPaddingSafeArea()
    self.setupTokensView()
    self.setupContinueButton()
    self.updateApproveButton()
    self.setUpGasFeeView()
    self.setUpChangeRateButton()
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.updateUIRefPrice()
    self.updateUIPendingTxIndicatorView()
    self.setupRateTimer()
  }
  
  fileprivate func setupRateTimer() {
    self.rateTimerView.lineWidth = 2
    self.rateTimerView.lineColor = UIColor(named: "buttonBackgroundColor")!
    self.rateTimerView.labelFont = UIFont.Kyber.regular(with: 10)
    self.rateTimerView.labelTextColor = UIColor(named: "buttonBackgroundColor")!
    self.rateTimerView.trailLineColor = UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
    self.rateTimerView.delegate = self
  }

  fileprivate func startRateTimer() {
    guard !self.viewModel.amountFrom.isEmpty || !self.viewModel.amountTo.isEmpty else {
      return
    }
    if self.rateTimerView.isHidden {
      self.rateTimerView.pause()
    }
    self.rateTimerView.start(beginingValue: 15, interval: 1)
  }

  fileprivate func stopRateTimer() {
    self.rateTimerView.pause()
  }

  fileprivate func setupTokensView() {

    self.fromAmountTextField.text = ""
    self.fromAmountTextField.adjustsFontSizeToFitWidth = true
    self.fromAmountTextField.delegate = self

    self.viewModel.updateAmount("", isSource: true)

    self.toAmountTextField.text = ""
    self.toAmountTextField.adjustsFontSizeToFitWidth = true
//    self.toAmountTextField.inputAccessoryView = self.toolBar
    self.toAmountTextField.delegate = self

    self.viewModel.updateAmount("", isSource: false)

    let tapBalanceGesture = UITapGestureRecognizer(target: self, action: #selector(self.balanceLabelTapped(_:)))
    self.balanceLabel.addGestureRecognizer(tapBalanceGesture)

    self.updateTokensView()
  }

  fileprivate func setUpGasFeeView() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
    self.gasFeeLabel.attributedText = self.viewModel.gasFeeString
    self.slippageLabel.text = self.viewModel.slippageString
  }

  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    self.pendingTxIndicatorView.isHidden = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty
  }
/*
  fileprivate func setupAdvancedSettingsView() {
    let isPromo = KNWalletPromoInfoStorage.shared.getDestWallet(from: self.viewModel.walletObject.address) != nil
    let viewModel = KAdvancedSettingsViewModel(hasMinRate: true, isPromo: isPromo, gasLimit: self.viewModel.estimateGasLimit)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    viewModel.updateMinRateValue(self.viewModel.estimatedRateDouble, percent: self.viewModel.minRatePercent)
    viewModel.updateViewHidden(isHidden: true)
    viewModel.updatePairToken("\(self.viewModel.from.symbol)-\(self.viewModel.to.symbol)")
    self.advancedSettingsView.updateViewModel(viewModel)
    self.heightConstraintForAdvacedSettingsView.constant = self.advancedSettingsView.height
    self.advancedSettingsView.delegate = self
    self.advancedSettingsView.updateGasLimit(self.viewModel.estimateGasLimit)
    self.advancedSettingsView.updateIsUsingReverseRoutingStatus(value: true)
    self.viewModel.isUsingReverseRouting = true
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraints()
  }
*/
  fileprivate func setupContinueButton() {
    self.continueButton.setTitle(
      NSLocalizedString("Swap Now", value: "Swap Now", comment: ""),
      for: .normal
    )
  }
  
  fileprivate func updateApproveButton() {
    self.approveButton.setTitle("Approve".toBeLocalised() + " " + self.viewModel.from.symbol, for: .normal)
  }

  fileprivate func setUpChangeRateButton() {
    
    guard let rate = self.viewModel.getCurrentRateObj(platform: self.viewModel.currentFlatform) else {
      self.changeRateButton.setImage(nil, for: .normal)
      return
    }
    let url = URL(string: rate.platformIcon)
    self.changeRateButton.kf.setImage(with: url, for: .normal, completionHandler: { result in
      switch result {
      case .success(let image):
        let resized = image.image.resizeImage(to: CGSize(width: 16, height: 16))
        self.changeRateButton.setImage(resized, for: .normal)
      case .failure(_):
        break
      }
    })
    self.changeRateButton.setTitle(rate.platformShort, for: .normal)
  }

  @IBAction func fromTokenButtonPressed(_ sender: UIButton) {
    let event = KSwapViewEvent.searchToken(
      from: self.viewModel.from,
      to: self.viewModel.to,
      isSource: true
    )
    self.delegate?.kSwapViewController(self, run: event)
  }

  @IBAction func toTokenButtonPressed(_ sender: UIButton) {
    let event = KSwapViewEvent.searchToken(
      from: self.viewModel.from,
      to: self.viewModel.to,
      isSource: false
    )
    self.delegate?.kSwapViewController(self, run: event)
  }

  @IBAction func swapButtonPressed(_ sender: UIButton) {
    if !self.viewModel.isFromTokenBtnEnabled { return }
    self.viewModel.showingRevertRate = false
    self.viewModel.swapTokens()
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.updateTokensView()
    self.updateEstimatedGasLimit()
    self.updateUIMinReceiveAmount()
    self.stopRateTimer()
  }

  @IBAction func historyListButtonTapped(_ sender: UIButton) {
    self.delegate?.kSwapViewController(self, run: .openHistory)
  }

  @IBAction func walletsListButtonTapped(_ sender: UIButton) {
    self.delegate?.kSwapViewController(self, run: .openWalletsList)
  }

  /*
   Continue token pressed
   - check amount valid (> 0 and <= balance)
   - check rate is valie (not zero)
   - (Temp) either from or to must be ETH
   - send exchange tx to coordinator for preparing trade
   */
  @IBAction func continueButtonPressed(_ sender: UIButton) {
    if self.showWarningDataInvalidIfNeeded(isConfirming: true) { return }
    let event = KSwapViewEvent.getExpectedRate(
      from: self.viewModel.from,
      to: self.viewModel.to,
      srcAmount: self.viewModel.amountFromBigInt,
      hint: self.viewModel.getHint(
        from: self.viewModel.from.address,
        to: self.viewModel.to.address,
        amount: self.viewModel.amountFromBigInt,
        platform: self.viewModel.currentFlatform
      )
    )
    self.delegate?.kSwapViewController(self, run: event)
  }

  @IBAction func maxAmountButtonTapped(_ sender: UIButton) {
    self.balanceLabelTapped(sender)
    self.startRateTimer()
  }

  @IBAction func changeRateButtonTapped(_ sender: UIButton) {
    let rates = self.viewModel.swapRates.3
    if rates.count >= 2 {
      self.delegate?.kSwapViewController(self, run: .openChooseRate(from: self.viewModel.from, to: self.viewModel.to, rates: rates, gasPrice: self.viewModel.gasPrice))
    }
  }

  @IBAction func approveButtonTapped(_ sender: UIButton) {
    guard let remain = self.viewModel.remainApprovedAmount else {
      return
    }
    self.delegate?.kSwapViewController(self, run: .sendApprove(token: remain.0, remain: remain.1))
  }

  @IBAction func warningRateButtonTapped(_ sender: UIButton) {
    guard !self.viewModel.refPriceDiffText.isEmpty else { return }
    let message = String(format: KNGeneralProvider.shared.priceAlertMessage.toBeLocalised(), self.viewModel.refPriceDiffText)
    self.showTopBannerView(
      with: "",
      message: message,
      icon: UIImage(named: "info_blue_icon"),
      time: 5.0
    )
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
  }

  fileprivate func updateFromAmountUIForSwapAllBalanceIfNeeded() {
    guard self.viewModel.isSwapAllBalance, self.viewModel.from.isETH else { return }
    self.fromAmountTextField.text = self.viewModel.allFromTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true, forSwapAllETH: true)
    self.updateViewAmountDidChange()
  }
  
  @IBAction func revertRateButtonTapped(_ sender: UIButton) {
    self.viewModel.showingRevertRate = !self.viewModel.showingRevertRate
    self.updateExchangeRateField()
  }
  
  @objc func keyboardSwapAllButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.viewModel.updateFocusingField(true)
    self.fromAmountTextField.text = self.viewModel.allFromTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true, forSwapAllETH: self.viewModel.from.isQuote)
    self.updateTokensView()
    self.updateViewAmountDidChange()
    if sender as? KSwapViewController != self {
      if self.viewModel.from.isQuoteToken {
        self.showSuccessTopBannerMessage(
          with: "",
          message: "A small amount of \(KNGeneralProvider.shared.quoteToken) will be used for transaction fee",
          time: 1.5
        )
      }
    }

    self.viewModel.isSwapAllBalance = true
    self.view.layoutIfNeeded()
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.view.layoutIfNeeded()
  }
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = { selected in
      let viewModel = SwitchChainWalletsListViewModel(selected: selected)
      let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
      self.present(secondPopup, animated: true, completion: nil)
    }
    self.present(popup, animated: true, completion: nil)
  }
  
  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.chainIconImage
    self.currentChainIcon.image = icon
    self.setUpGasFeeView()
  }

  func coordinatorUpdateGasPriceCached() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
    self.setUpGasFeeView()
//    self.updateAdvancedSettingsView()
    self.updateFromAmountUIForSwapAllBalanceIfNeeded()
  }

  fileprivate func updateAllRates() {
    let amt = self.viewModel.isFocusingFromAmount ? self.viewModel.amountFromBigInt : self.viewModel.amountToBigInt
    let event = KSwapViewEvent.getAllRates(from: self.viewModel.from, to: self.viewModel.to, amount: amt, focusSrc: self.viewModel.isFocusingFromAmount)
    self.delegate?.kSwapViewController(self, run: event)
  }

  fileprivate func updateRefPrice() {
    self.delegate?.kSwapViewController(self, run: .getRefPrice(from: self.viewModel.from, to: self.viewModel.to))
  }

  fileprivate func updateEstimatedGasLimit() {
    let event = KSwapViewEvent.getGasLimit(
      from: self.viewModel.from,
      to: self.viewModel.to,
      srcAmount: self.viewModel.amountToEstimate,
      rawTx: self.viewModel.buildRawSwapTx()
    )
    //Dismiss event call if the same parameter call within 5 sec
//    if let previousEvent = self.previousCallEvent, previousEvent == event, Date().timeIntervalSince1970 - self.previousCallTimeStamp < 5 {
//      return
//    }
//    self.previousCallEvent = event
//    self.previousCallTimeStamp = Date().timeIntervalSince1970
    self.delegate?.kSwapViewController(self, run: event)
  }

  /*
   Return true if data is invalid and a warning message is shown,
   false otherwise
  */
  fileprivate func showWarningDataInvalidIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming && !self.isErrorMessageEnabled { return false }
    if !isConfirming && (self.fromAmountTextField.isEditing || self.toAmountTextField.isEditing) { return false }
    let estRate = self.viewModel.getSwapRate(from: self.viewModel.from.address.lowercased(), to: self.viewModel.to.address.lowercased(), amount: self.viewModel.amountFromBigInt, platform: self.viewModel.currentFlatform)
    let estRateBigInt = BigInt(estRate)
    guard self.viewModel.from != self.viewModel.to else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: NSLocalizedString("can.not.swap.same.token", value: "Can not swap the same token", comment: ""),
        time: 1.5
      )
      return true
    }
    guard !self.viewModel.amountFrom.isEmpty else {
      if isConfirming == true {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("invalid.input", value: "Invalid input", comment: ""),
          message: NSLocalizedString("please.enter.an.amount.to.continue", value: "Please enter an amount to continue", comment: "")
        )
      }
      return true
    }
    if estRateBigInt?.isZero == true {
      self.showWarningTopBannerMessage(
        with: "",
        message: "Can not find the exchange rate"
      )
      return true
    }
    guard self.viewModel.isBalanceEnough else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: NSLocalizedString("balance.not.enough.to.make.transaction", value: "Balance is not enough to make the transaction.", comment: "")
      )
      return true
    }
    guard !self.viewModel.isAmountTooSmall else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: NSLocalizedString("amount.too.small.to.perform.swap", value: "Amount too small to perform swap, minimum equivalent to 0.001 ETH", comment: "")
      )
      return true
    }
    if isConfirming {
      let quoteToken = KNGeneralProvider.shared.quoteToken
      guard self.viewModel.isHavingEnoughETHForFee else {
        let fee = self.viewModel.feeBigInt
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("Insufficient \(quoteToken) for transaction", value: "Insufficient \(quoteToken) for transaction", comment: ""),
          message: String(format: "Deposit more \(quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), fee.shortString(units: .ether, maxFractionDigits: 5))
        )
        return true
      }
      guard estRateBigInt != nil, estRateBigInt?.isZero == false else {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("rate.might.change", value: "Rate might change", comment: ""),
          message: NSLocalizedString("please.wait.for.expected.rate.updated", value: "Please wait for expected rate to be updated", comment: "")
        )
        return true
      }
      guard EtherscanTransactionStorage.shared.isContainInsternalSendTransaction() == false else {
        self.showWarningTopBannerMessage(
          with: "",
          message: "Please wait for transaction is completed"
        )
        return true
      }
    }
    return false
  }

  @IBAction func gasPriceSelectButtonTapped(_ sender: UIButton) {
    let event = KSwapViewEvent.openGasPriceSelect(
      gasLimit: self.viewModel.estimateGasLimit,
      selectType: self.viewModel.selectedGasPriceType,
      pair: "\(self.viewModel.from.symbol)-\(self.viewModel.to.symbol)",
      minRatePercent: self.viewModel.minRatePercent
    )
    self.delegate?.kSwapViewController(self, run: event)
  }
  
  fileprivate func checkUpdateApproveButton() {
    guard let token = self.viewModel.approvingToken else {
      return
    }
    if EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty {
      self.updateUIForSendApprove(isShowApproveButton: false)
      self.viewModel.approvingToken = nil
    }
    let pending = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().filter({ (item) -> Bool in
      return item.transactionDetailDescription.lowercased() == token.address.lowercased() && item.type == .allowance
    })
    if pending.isEmpty {
      self.updateUIForSendApprove(isShowApproveButton: false)
      self.viewModel.approvingToken = nil
    }
  }
}

// MARK: Update UIs
extension KSwapViewController {
  /*
   Update tokens view when either from or to tokens changed
   - updatedFrom: true if from token is changed
   - updatedTo: true if to token is changed
   */
  func updateTokensView(updatedFrom: Bool = true, updatedTo: Bool = true) {
    if updatedFrom {
      self.fromTokenButton.setTitle(self.viewModel.tokenButtonText(isSource: true), for: .normal)
    }
    if updatedTo {
      self.toTokenButton.setTitle(self.viewModel.tokenButtonText(isSource: false), for: .normal)
    }
    //TODO: remove est rate cache logic
//    self.viewModel.updateEstimatedRateFromCachedIfNeeded()
    // call update est rate from node
    self.updateAllRates()
//    self.updateEstimatedRate(showError: updatedFrom || updatedTo)
//    self.updateReferencePrice()
    self.balanceLabel.text = self.viewModel.balanceDisplayText
    self.updateAllowance()

    // update tokens button in case promo wallet
    self.toTokenButton.isEnabled = self.viewModel.isToTokenBtnEnabled
    self.fromTokenButton.isEnabled = self.viewModel.isFromTokenBtnEnabled
    self.updateExchangeRateField()
    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount
    self.updateUIRefPrice()
    self.updateRefPrice()

    self.view.layoutIfNeeded()
  }

  fileprivate func updateExchangeRateField() {
    self.exchangeRateLabel.text = self.viewModel.exchangeRateText
  }

  fileprivate func updateAllowance() {
    self.delegate?.kSwapViewController(self, run: .checkAllowance(token: self.viewModel.from))
  }

  @objc func balanceLabelTapped(_ sender: Any) {
    self.keyboardSwapAllButtonPressed(sender)
  }

  fileprivate func updateUIForSendApprove(isShowApproveButton: Bool, token: TokenObject? = nil) {
    if let unwrapped = token, unwrapped.contract.lowercased() != self.viewModel.from.contract.lowercased() {
      return
    }
    self.updateApproveButton()
    if isShowApproveButton {
      self.approveButtonLeftPaddingContraint.constant = 37
      self.approveButtonRightPaddingContaint.constant = 15
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 999)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.continueButton.isEnabled = false
      self.continueButton.alpha = 0.2
      
      if let approveToken = self.viewModel.approvingToken, approveToken.isEqual(self.viewModel.from) {
        // only disable approveButton when current approvingToken is source token
        self.approveButton.isEnabled = false
        self.approveButton.alpha = 0.2
      } else {
        self.approveButton.isEnabled = true
        self.approveButton.alpha = 1
      }
    } else {
      self.approveButtonLeftPaddingContraint.constant = 0
      self.approveButtonRightPaddingContaint.constant = 37
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 999)
      self.continueButton.isEnabled = true
      self.continueButton.alpha = 1
    }

    self.view.layoutIfNeeded()
  }

  fileprivate func updateUIRefPrice() {
    let change = self.viewModel.refPriceDiffText
    self.rateWarningLabel.text = change
  }

  fileprivate func updateUIMinReceiveAmount() {
    if self.viewModel.isFocusingFromAmount {
      self.minReceivedAmount.text = self.viewModel.displayMinDestAmount
      self.minReceivedAmountTitleLabel.text = "Minimum recieved"
    } else {
      self.minReceivedAmount.text = self.viewModel.displayMaxSoldAmount
      self.minReceivedAmountTitleLabel.text = "Maximum sold"
    }
  }
}

// MARK: Update from coordinator
extension KSwapViewController {
  /*
   Update new session when current wallet is changed, update all UIs
   */
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.updateTokensView()
    self.updateViewAmountDidChange()
    self.walletsListButton.setTitle(self.viewModel.wallet.getWalletObject()?.name ?? "---", for: .normal)
    self.balanceLabel.text = self.viewModel.balanceDisplayText
    self.updateUIPendingTxIndicatorView()
    self.stopRateTimer()
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateWalletObjects() {
    self.viewModel.updateWalletObject()
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.balanceLabel.text = self.viewModel.balanceDisplayText
    self.view.layoutIfNeeded()
  }

  func coordinatorDidUpdateExpectedRate(from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt) {
    self.viewModel.updateExpectedRate(for: from, to: to, amount: amount, rate: rate)
    if self.viewModel.isFocusingFromAmount {
      self.toAmountTextField.text = self.viewModel.expectedReceivedAmountText
      self.viewModel.updateAmount(self.toAmountTextField.text ?? "", isSource: false)
    } else {
      self.fromAmountTextField.text = self.viewModel.expectedExchangeAmountText
      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    }
    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount
    if self.viewModel.isTappedSwapAllBalance {
      self.keyboardSwapAllButtonPressed(self)
      self.viewModel.isTappedSwapAllBalance = false
    }
    self.view.layoutIfNeeded()
    self.delegate?.kSwapViewController(self, run: .getLatestNonce)
  }

  /*
   Update estimate gas limit, check if the from, to, amount are all the same as current value in the model    Update UIs according to new values
   */
  func coordinatorDidUpdateGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    self.viewModel.updateEstimateGasLimit(
      for: from,
      to: to,
      amount: amount,
      gasLimit: gasLimit
    )
    
    self.setUpGasFeeView()
    self.updateFromAmountUIForSwapAllBalanceIfNeeded()
  }

  /*
   Update selected token
   - token: New selected token
   - isSource: true if selected token is from, otherwise it is to
   Update UIs according to new values
   */
  func coordinatorUpdateSelectedToken(_ token: TokenObject, isSource: Bool, isWarningShown: Bool = true) {
    if isSource, !self.fromTokenButton.isEnabled { return }
    if !isSource, !self.toTokenButton.isEnabled { return }
    if isSource, self.viewModel.from == token { return }
    if !isSource, self.viewModel.to == token { return }
    self.viewModel.showingRevertRate = false
    self.viewModel.updateSelectedToken(token, isSource: isSource)
    // support for promo wallet
    let isUpdatedTo: Bool = {
      if token.isPromoToken, isSource,
        let dest = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.viewModel.walletObject.address),
        let destToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == dest.uppercased() }) {
        self.viewModel.updateSelectedToken(destToken, isSource: false)
        return true
      }
      return !isSource
    }()

    
    self.toAmountTextField.text = ""
    self.fromAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.updateTokensView(updatedFrom: isSource, updatedTo: isUpdatedTo)
    if self.viewModel.from == self.viewModel.to && isWarningShown {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: NSLocalizedString("can.not.swap.same.token", value: "Can not swap the same token", comment: ""),
        time: 1.5
      )
    }
    self.viewModel.gasPriceSelectedAmount = ("", "")
    self.updateApproveButton()
    //TODO: reset only swap button on screen, can be optimize with
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.updateEstimatedGasLimit()
    self.updateAllowance()
    self.updateAllRates()
    self.updateUIMinReceiveAmount()
    self.stopRateTimer()
    self.view.layoutIfNeeded()
  }

  /*
   Result from sending exchange token
   */
  func coordinatorExchangeTokenDidReturn(result: Result<String, AnyError>) {
    if case .failure(let error) = result {
      self.displayError(error: error)
    }
  }
  /*
   Show transaction status after user confirmed transaction
   */
  func coordinatorExchangeTokenUserDidConfirmTransaction() {
    // Reset exchange amount
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.viewModel.updateFocusingField(true)
    self.toAmountTextField.text = ""
    self.fromAmountTextField.text = ""
    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount
//    self.updateExchangeRateField()
    self.view.layoutIfNeeded()
  }

  func coordinatorTrackerRateDidUpdate() {
    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount
//    self.updateExchangeRateField()
  }
  /*
   - gasPrice: new gas price after user finished selected gas price from set gas price view
   */
  func coordinatorExchangeTokenDidUpdateGasPrice(_ gasPrice: BigInt?) {
    if let gasPrice = gasPrice {
      self.viewModel.updateGasPrice(gasPrice)
      self.updateFromAmountUIForSwapAllBalanceIfNeeded()
    }
    self.setUpGasFeeView()
    self.view.layoutIfNeeded()
  }

  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.setUpGasFeeView()
    self.updateFromAmountUIForSwapAllBalanceIfNeeded()
  }

  func coordinatorDidUpdateMinRatePercentage(_ value: CGFloat) {
    self.viewModel.updateExchangeMinRatePercent(Double(value))
    self.setUpGasFeeView()
    self.updateUIMinReceiveAmount()
  }

  func coordinatorDidUpdateRates(from: TokenObject, to: TokenObject, srcAmount: BigInt, rates: [Rate]) {
    self.viewModel.updateSwapRates(from: from, to: to, amount: srcAmount, rates: rates)
    self.updateInputFieldsUI()
    self.viewModel.reloadBestPlatform()
    self.updateExchangeRateField()
    self.setUpChangeRateButton()
    self.updateUIRefPrice()
    self.updateUIMinReceiveAmount()
  }

  func coordinatorFailUpdateRates() {
    //TODO: show error loading rate if needed on UI
  }

  func coordinatorDidUpdatePlatform(_ platform: String) {
    self.viewModel.currentFlatform = platform
    self.viewModel.gasPriceSelectedAmount = (self.viewModel.amountFrom, self.viewModel.amountTo)
    self.setUpChangeRateButton()
    self.updateExchangeRateField()
    self.updateInputFieldsUI()
    self.setUpGasFeeView()
    self.updateEstimatedGasLimit()
  }

  func coordinatorDidUpdateAllowance(token: TokenObject, allowance: BigInt) {
    guard !self.viewModel.from.isQuoteToken else {
      self.updateUIForSendApprove(isShowApproveButton: false)
      return
    }
    if self.viewModel.from.getBalanceBigInt() > allowance {
      self.viewModel.remainApprovedAmount = (token, allowance)
      self.updateUIForSendApprove(isShowApproveButton: true, token: token)
    } else {
      //TODO: need to check more to avoid lagging ui
      self.updateUIForSendApprove(isShowApproveButton: false)
    }
  }

  func coordinatorDidFailUpdateAllowance(token: TokenObject) {
    //TODO: handle error
  }

  func coordinatorSuccessApprove(token: TokenObject) {
    self.viewModel.approvingToken = token
    self.updateUIForSendApprove(isShowApproveButton: true, token: token)
  }

  func coordinatorFailApprove(token: TokenObject) {
    //TODO: show error message
    self.showErrorMessage()
    self.updateUIForSendApprove(isShowApproveButton: true, token: token)
  }

  func coordinatorSuccessUpdateLatestNonce(nonce: Int) {
    self.viewModel.latestNonce = nonce
    let raw = self.viewModel.buildRawSwapTx()
    self.delegate?.kSwapViewController(self, run: .buildTx(rawTx: raw))
  }

  func coordinatorFailUpdateLatestNonce() {
    self.showErrorMessage()
    self.hideLoading()
  }

  func coordinatorSuccessUpdateEncodedTx(object: TxObject) {
    self.hideLoading()
    guard let signTx = self.viewModel.buildSignSwapTx(object) else { return }
    let rate = self.viewModel.estRate ?? BigInt(0)
    let amount: BigInt = {
      if self.viewModel.isFocusingFromAmount {
        if self.viewModel.isSwapAllBalance {
          let balance = self.viewModel.from.getBalanceBigInt()
          if !self.viewModel.from.isQuoteToken { return balance } // token, no need minus fee
          let fee = self.viewModel.allETHBalanceFee
          return max(BigInt(0), balance - fee)
        }
        return self.viewModel.amountFromBigInt
      }
      let expectedExchange: BigInt = {
        if rate.isZero { return rate }
        let amount = self.viewModel.amountToBigInt
        return amount * BigInt(10).power(self.viewModel.from.decimals) / rate
      }()
      return expectedExchange
    }()
    let gasLimit = BigInt(object.gasLimit.drop0x, radix: 16) ?? self.viewModel.estimateGasLimit
    let exchange = KNDraftExchangeTransaction(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: rate,
      minRate: self.viewModel.minRate,
      gasPrice: self.viewModel.gasPrice,
      gasLimit: gasLimit,
      expectedReceivedString: self.viewModel.amountTo,
      hint: self.viewModel.getHint(from: self.viewModel.from.address, to: self.viewModel.to.address, amount: self.viewModel.amountFromBigInt, platform: self.viewModel.currentFlatform)
    )
    self.delegate?.kSwapViewController(self, run: .confirmSwap(data: exchange, tx: signTx, hasRateWarning: !self.viewModel.refPriceDiffText.isEmpty, platform: self.viewModel.currentFlatform, rawTransaction: object, minReceiveDest: self.viewModel.minDestQty))
  }

  func coordinatorFailUpdateEncodedTx() {
    self.showErrorMessage()
    self.hideLoading()
  }

  func coordinatorSuccessSendTransaction() {
    print("[Debug] send success")
    self.hideLoading()
  }

  func coordinatorFailSendTransaction() {
    self.showErrorMessage()
    self.hideLoading()
  }

  func coordinatorSuccessUpdateRefPrice(from: TokenObject, to: TokenObject, change: String, source: [String]) {
    self.viewModel.updateRefPrice(from: from, to: to, change: change, source: source)
    self.updateUIRefPrice()
  }

  func coordinatorUpdateIsUseGasToken(_ state: Bool) {
  }

  fileprivate func showErrorMessage() {
    self.showWarningTopBannerMessage(
      with: "",
      message: "Something went wrong, please try again later".toBeLocalised(),
      time: 2.0
    )
  }

  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
    self.checkUpdateApproveButton()
  }

  func coordinatorDidUpdateChain() {
    self.updateUISwitchChain()
    self.viewModel.resetDefaultTokensPair()
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.updateTokensView()
    self.updateViewAmountDidChange()
    self.balanceLabel.text = self.viewModel.balanceDisplayText
    self.setUpChangeRateButton()
    self.stopRateTimer()
  }
}

// MARK: UITextFieldDelegate
extension KSwapViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.viewModel.updateAmount("", isSource: textField == self.fromAmountTextField)
    self.viewModel.isSwapAllBalance = false
    self.updateViewAmountDidChange()
    self.updateEstimatedGasLimit()
    self.stopRateTimer()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let prevDest = self.toAmountTextField.text ?? ""
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()
    
    
    if textField == self.fromAmountTextField && text.amountBigInt(decimals: self.viewModel.from.decimals) == nil { return false }
    if textField == self.toAmountTextField && text.amountBigInt(decimals: self.viewModel.to.decimals) == nil { return false }
    let double: Double = {
      if textField == self.fromAmountTextField {
        let bigInt = Double(text.amountBigInt(decimals: self.viewModel.from.decimals) ?? BigInt(0))
        return Double(bigInt) / pow(10.0, Double(self.viewModel.from.decimals))
      }
      let bigInt = Double(text.amountBigInt(decimals: self.viewModel.to.decimals) ?? BigInt(0))
      return Double(bigInt) / pow(10.0, Double(self.viewModel.to.decimals))
    }()
    if double > 1e9 && (textField.text?.count ?? 0) < text.count { return false } // more than 1B tokens
    textField.text = text
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.viewModel.updateAmount(text, isSource: textField == self.fromAmountTextField)
    
    self.stopRateTimer()
    self.keyboardTimer?.invalidate()
    self.keyboardTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(KSwapViewController.keyboardPauseTyping),
            userInfo: ["textField": textField],
            repeats: false)

    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.isSwapAllBalance = false
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.updateViewAmountDidChange()
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateAllRates()
    self.updateEstimatedGasLimit()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = self.showWarningDataInvalidIfNeeded()
    }
  }

  fileprivate func updateInputFieldsUI() {
    if self.viewModel.isFocusingFromAmount {
      self.toAmountTextField.text = self.viewModel.expectedReceivedAmountText
      self.viewModel.updateAmount(self.toAmountTextField.text ?? "", isSource: false)
    } else {
      self.fromAmountTextField.text = self.viewModel.expectedExchangeAmountText
      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    }

    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount
  }
  
  @objc func keyboardPauseTyping(timer: Timer) {
    self.startRateTimer()
    self.updateViewAmountDidChange()
  }

  fileprivate func updateViewAmountDidChange() {
    self.updateInputFieldsUI()
    self.updateAllRates()
    self.updateExchangeRateField()
    self.updateUIMinReceiveAmount()
    self.view.layoutIfNeeded()
  }
}

extension KSwapViewController: SRCountdownTimerDelegate {
  @objc func timerDidStart(sender: SRCountdownTimer) {
    sender.isHidden = false
  }

  @objc func timerDidPause(sender: SRCountdownTimer) {
    sender.isHidden = true
  }

  @objc func timerDidResume(sender: SRCountdownTimer) {
  }

  @objc func timerDidEnd(sender: SRCountdownTimer, elapsedTime: TimeInterval) {
    sender.isHidden = true
    self.updateAllRates()
    self.startRateTimer()
  }
}
