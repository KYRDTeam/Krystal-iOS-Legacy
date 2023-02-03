//
//  SwapV2ViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import UIKit
import Lottie
import BigInt
import BaseModule
import TokenModule

class SwapV2ViewController: InAppBrowsingViewController {
  @IBOutlet weak var platformTableView: UITableView!
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var sourceTokenLabel: UILabel!
  @IBOutlet weak var destTokenLabel: UILabel!
  @IBOutlet weak var sourceBalanceLabel: UILabel!
  @IBOutlet weak var sourceTokenIcon: UIImageView!
  @IBOutlet weak var destBalanceLabel: UILabel!
  @IBOutlet weak var destTokenIcon: UIImageView!
  @IBOutlet weak var destViewHeight: NSLayoutConstraint!
  @IBOutlet weak var sourceView: UIView!
  @IBOutlet weak var rateLoadingView: CircularArrowProgressView!
  @IBOutlet weak var loadingView: UIView!
  @IBOutlet weak var expandIcon: UIImageView!
  @IBOutlet weak var sourceTextField: UITextField!
  @IBOutlet weak var fetchingAnimationView: LottieAnimationView!
  @IBOutlet weak var infoExpandButton: UIButton!
  @IBOutlet weak var infoSeparatorView: UIView!
  @IBOutlet weak var sourceTokenView: UIView!
  @IBOutlet weak var destTokenView: UIView!
  @IBOutlet weak var sourceAmountUsdLabel: UILabel!
  @IBOutlet weak var settingButton: UIButton!
  // Info Views
  @IBOutlet weak var rateInfoView: SwapInfoView!
  @IBOutlet weak var slippageInfoView: SwapInfoView!
  @IBOutlet weak var minReceiveInfoView: SwapInfoView!
  @IBOutlet weak var gasFeeInfoView: SwapInfoView!
  @IBOutlet weak var maxGasFeeInfoView: SwapInfoView!
  @IBOutlet weak var priceImpactInfoView: SwapInfoView!
  @IBOutlet weak var routeInfoView: SwapInfoView!
  
  // Warning Views
  @IBOutlet weak var approveGuideView: UIView!
  @IBOutlet weak var approveGuideIcon: UIImageView!
  @IBOutlet weak var approveGuideLabel: UILabel!
  @IBOutlet weak var piWarningView: UIView!
  @IBOutlet weak var piWarningIcon: UIImageView!
  @IBOutlet weak var piWarningLabel: UILabel!
  @IBOutlet weak var errorView: UIView!
  @IBOutlet weak var errorIcon: UIImageView!
  @IBOutlet weak var errorLabel: UILabel!
  
   // Header
  @IBOutlet weak var dotView: UIView!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var loadingIndicator: SRCountdownTimer!

  var viewModel: SwapV2ViewModel!
  
  let platformRateItemHeight: CGFloat = 96
  let loadingViewHeight: CGFloat = 142
  let rateReloadingInterval: Int = 30
  var timer: Timer?
  var remainingTime: Int = 0
  
  var isInfoExpanded: Bool = false {
    didSet {
      UIView.animate(withDuration: 0.2) {
        self.infoExpandButton.setImage(self.isInfoExpanded ? Images.swapPullup : Images.swapDropdown, for: .normal)
        self.maxGasFeeInfoView.isHidden = !self.isInfoExpanded
        self.priceImpactInfoView.isHidden = !self.isInfoExpanded
      }
    }
  }
  
  var canExpand: Bool = false {
    didSet {
      self.expandIcon.isHidden = !canExpand
    }
  }
  
  var titleForContinueButton: String {
    return KNGeneralProvider.shared.isBrowsingMode ? Strings.connectWallet : Strings.reviewSwap
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tabBarItem.accessibilityIdentifier = "menuSwap"
    viewModel.appDidSwitchChain()
    configureViews()
    resetViews()
    bindViewModel()
  }
  
  override func handleAddWalletTapped() {
    super.handleAddWalletTapped()
    MixPanelManager.track("swap_connect_wallet", properties: ["screenid": "swap"])
  }
  
  override func handleWalletButtonTapped() {
    super.handleWalletButtonTapped()
    MixPanelManager.track("swap_select_wallet", properties: ["screenid": "swap"])
  }
  
  override func handleChainButtonTapped() {
    super.handleChainButtonTapped()
    MixPanelManager.track("swap_select_chain", properties: ["screenid": "swap"])
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if KNGeneralProvider.shared.isBrowsingMode {
      self.viewModel.appDidSwitchAddress()
      self.viewModel.appDidSwitchChain()
    }
    navigationController?.setNavigationBarHidden(true, animated: true)
    MixPanelManager.track("swap_open", properties: ["screenid": "swap"])
  }
  
  deinit {
    timer?.invalidate()
    timer = nil
  }

  func configureViews() {
    setupButtons()
    setupAnimation()
    setupSourceView()
    setupInfoViews()
    setupTableView()
    setupLoadingIndicator()
    setupRateLoadingView()
    setupDropdownView()
    setupSourceDestTokensView()
  }
  
  func resetViews() {
    rateInfoView.isHidden = true
    slippageInfoView.isHidden = true
    minReceiveInfoView.isHidden = true
    gasFeeInfoView.isHidden = true
    maxGasFeeInfoView.isHidden = true
    priceImpactInfoView.isHidden = true
    routeInfoView.isHidden = true
  }
  
  func setupLoadingIndicator() {
    self.loadingIndicator.lineWidth = 2
    self.loadingIndicator.lineColor = UIColor.Kyber.primaryGreenColor
    self.loadingIndicator.labelTextColor = UIColor.Kyber.primaryGreenColor
    self.loadingIndicator.trailLineColor = UIColor.Kyber.primaryGreenColor.withAlphaComponent(0.2)
    self.loadingIndicator.isLoadingIndicator = true
    self.loadingIndicator.isLabelHidden = true
    self.loadingIndicator.isHidden = true
  }
  
  func setupAnimation() {
//    DispatchQueue.main.async {
      self.fetchingAnimationView.animation = LottieAnimation.rocket
      self.fetchingAnimationView.contentMode = .scaleAspectFit
      self.fetchingAnimationView.loopMode = .loop
      self.fetchingAnimationView.play()
//    }
  }
  
  func setupButtons() {
    settingButton.setImage(Images.swapSettings.withRenderingMode(.alwaysTemplate), for: .normal)
    
    continueButton.setBackgroundColor(.Kyber.primaryGreenColor, forState: .normal)
    continueButton.setBackgroundColor(.Kyber.evenBg, forState: .disabled)
    continueButton.setTitleColor(.black, for: .normal)
    continueButton.setTitleColor(.white.withAlphaComponent(0.3), for: .disabled)
    continueButton.setTitle(titleForContinueButton, for: .normal)
  }
  
  func setupSourceView() {
    sourceBalanceLabel.isUserInteractionEnabled = true
    sourceBalanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sourceBalanceTapped)))
    sourceTextField.setPlaceholder(text: NumberFormatUtils.zeroPlaceHolder(), color: .white.withAlphaComponent(0.5))
    sourceTextField.delegate = self
  }
  
  func setupDropdownView() {
    expandIcon.isUserInteractionEnabled = true
    expandIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onToggleExpand)))
  }
  
  func setupSourceDestTokensView() {
    sourceTokenView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSourceTokenSearch)))
    destTokenView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openDestTokenSearch)))
  }
  
  func setupInfoViews() {
    rateInfoView.setTitle(title: Strings.swapRate, underlined: false, shouldShowIcon: true)
    rateInfoView.onTapRightIcon = { [weak self] in
      self?.viewModel.showRevertedRate.toggle()
    }
    
    slippageInfoView.setTitle(title: Strings.maxSlippage, underlined: true)
    slippageInfoView.iconImageView.isHidden = true
    slippageInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapSlippageInfo, icon: Images.swapInfo)
    }
    slippageInfoView.onTapValue = { [weak self] in
      self?.viewModel.openSettings()
    }
    
    minReceiveInfoView.setTitle(title: Strings.minReceived, underlined: true)
    minReceiveInfoView.iconImageView.isHidden = true
    minReceiveInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapMinReceiveInfo, icon: Images.swapInfo)
    }
    
    gasFeeInfoView.setTitle(title: Strings.estNetworkFee, underlined: true)
    gasFeeInfoView.iconImageView.isHidden = true
    gasFeeInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapTxnFeeInfo, icon: Images.swapInfo)
    }
    gasFeeInfoView.onTapValue = { [weak self] in
      self?.viewModel.openSettings()
    }
    
    maxGasFeeInfoView.setTitle(title: Strings.maxNetworkFee, underlined: true)
    maxGasFeeInfoView.iconImageView.isHidden = true
    maxGasFeeInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapTxnMaxFeeInfo, icon: Images.swapInfo)
    }
    
    priceImpactInfoView.setTitle(title: Strings.priceImpact, underlined: true)
    priceImpactInfoView.iconImageView.isHidden = true
    priceImpactInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapPriceImpactInfo, icon: Images.swapInfo)
    }
    
    routeInfoView.setTitle(title: Strings.route, underlined: true)
  }
  
  func setupTableView() {
    platformTableView.registerCellNib(SwapV2PlatformCell.self)
    platformTableView.delegate = self
    platformTableView.dataSource = self
    destViewHeight.constant = 112
  }
    
  override func onAppSwitchAddress() {
    super.onAppSwitchAddress()
      
    self.sourceTextField.text = nil
  }
  
  func bindViewModel() {
    viewModel.currentChain.observeAndFire(on: self) { [weak self] chain in
      self?.containerView.isHidden = !KNGeneralProvider.shared.currentChain.isSupportSwap()
    }
    
    viewModel.platformRatesViewModels.observe(on: self) { [weak self] _ in
      self?.reloadRates()
    }
    
    viewModel.sourceToken.observeAndFire(on: self) { [weak self] token in
      DispatchQueue.main.async {
        self?.sourceTokenLabel.text = token?.symbol
        self?.sourceTextField.text = nil
        if let token = token {
          self?.sourceTokenIcon.isHidden = false
          self?.sourceTokenIcon.setImage(urlString: token.logo, symbol: token.symbol)
        } else {
          self?.sourceTokenIcon.isHidden = true
          self?.sourceTokenLabel.text = Strings.selectToken
        }
      }
    }
    
    viewModel.destToken.observeAndFire(on: self) { [weak self] token in
      DispatchQueue.main.async {
        self?.destTokenLabel.text = token?.symbol
        if let token = token {
          self?.destTokenIcon.isHidden = false
          self?.destTokenIcon.setImage(urlString: token.logo, symbol: token.symbol)
        } else {
          self?.destTokenIcon.isHidden = true
          self?.destTokenLabel.text = Strings.selectToken
        }
      }
    }
    
    viewModel.sourceBalance.observeAndFire(on: self) { [weak self] balance in
      guard let self = self else { return }
      guard let sourceToken = self.viewModel.sourceToken.value else { return }
      let amount = balance ?? .zero
      let soureSymbol = sourceToken.symbol
      let decimals = sourceToken.decimals
      DispatchQueue.main.async {
        self.sourceBalanceLabel.text = "\(NumberFormatUtils.balanceFormat(value: amount, decimals: decimals)) \(soureSymbol)"
      }
    }
    
    viewModel.destBalance.observeAndFire(on: self) { [weak self] balance in
      guard let self = self else { return }
      guard let destToken = self.viewModel.destToken.value else { return }
      let destSymbol = destToken.symbol
      let decimals = destToken.decimals
      let amount = balance ?? .zero
      DispatchQueue.main.async {
        self.destBalanceLabel.text = "\(NumberFormatUtils.balanceFormat(value: amount, decimals: decimals)) \(destSymbol)"
      }
    }
    
    viewModel.rateString.observeAndFire(on: self) { [weak self] rate in
      self?.rateInfoView.setValue(value: rate, highlighted: false)
    }
    
    viewModel.slippageString.observeAndFire(on: self) { [weak self] string in
      self?.slippageInfoView.setValue(value: string, highlighted: true)
    }
    
    viewModel.minReceiveString.observeAndFire(on: self) { [weak self] string in
      self?.minReceiveInfoView.setValue(value: string, highlighted: false)
    }
    
    viewModel.estimatedGasFeeString.observeAndFire(on: self) { [weak self] string in
      self?.gasFeeInfoView.setValue(value: string, highlighted: true)
    }
    
    viewModel.maxGasFeeString.observeAndFire(on: self) { [weak self] string in
      self?.maxGasFeeInfoView.setValue(value: string, highlighted: false)
    }
    
    viewModel.selectedPlatformRate.observeAndFire(on: self) { [weak self] rate in
      guard let self = self else { return }
      self.infoSeparatorView.isHidden = rate == nil
      self.rateInfoView.isHidden = rate == nil
      self.slippageInfoView.isHidden = rate == nil
      self.minReceiveInfoView.isHidden = rate == nil
      self.gasFeeInfoView.isHidden = rate == nil
      self.maxGasFeeInfoView.isHidden = rate == nil || !self.isInfoExpanded
      self.priceImpactInfoView.isHidden = rate == nil || !self.isInfoExpanded
    }
    
    viewModel.state.observeAndFire(on: self) { [weak self] state in
      guard let self = self else { return }
      switch state {
      case .emptyAmount:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle(Strings.enterAnAmount, for: .normal)
        self.rateLoadingView.isHidden = true
        self.platformTableView.isHidden = true
        self.errorView.isHidden = true
        self.loadingView.isHidden = true
        self.destViewHeight.constant = CGFloat(112)
        self.expandIcon.isHidden = true
        self.approveGuideView.isHidden = true
        self.piWarningView.isHidden = true
      case .fetchingRates:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle(Strings.fetchingBestRates, for: .normal)
        self.platformTableView.isHidden = true
        self.loadingView.isHidden = false
        self.expandIcon.isHidden = true
        self.approveGuideView.isHidden = true
        self.destViewHeight.constant = CGFloat(112) + self.loadingViewHeight + 24
        self.errorView.isHidden = true
        self.piWarningView.isHidden = true
        self.loadingIndicator.isHidden = true
        self.rateLoadingView.isHidden = true
      case .refreshingRates:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle(Strings.fetchingBestRates, for: .normal)
        self.loadingIndicator.isHidden = false
        self.rateLoadingView.isHidden = true
      case .notConnected:
        self.continueButton.isEnabled = true
        self.continueButton.setTitle(Strings.connectWallet, for: .normal)
        self.errorView.isHidden = true
        self.approveGuideView.isHidden = true
        self.loadingIndicator.end()
        self.loadingIndicator.isHidden = true
        self.rateLoadingView.isHidden = false
        self.resetCountdownView()
      case .rateNotFound:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle(self.titleForContinueButton, for: .normal)
        self.rateLoadingView.isHidden = false
        self.platformTableView.isHidden = true
        self.loadingView.isHidden = true
        self.approveGuideView.isHidden = true
        self.destViewHeight.constant = CGFloat(112)
        self.errorView.isHidden = false
        self.errorLabel.text = Strings.swapRateNotFound
        self.loadingIndicator.end()
        self.loadingIndicator.isHidden = true
        self.rateLoadingView.isHidden = false
        self.resetCountdownView()
      case .insufficientBalance:
        if KNGeneralProvider.shared.isBrowsingMode {
          self.continueButton.isEnabled = true
          self.continueButton.setTitle(self.titleForContinueButton, for: .normal)
        } else {
          self.continueButton.isEnabled = false
          self.continueButton.setTitle(String(format: Strings.insufficientTokenBalance, self.viewModel.sourceToken.value?.symbol ?? ""), for: .normal)
        }
        self.errorView.isHidden = true
        self.platformTableView.isHidden = false
        self.approveGuideView.isHidden = true
        self.rateLoadingView.isHidden = false
        self.loadingView.isHidden = true
        self.loadingIndicator.end()
        self.loadingIndicator.isHidden = true
        self.resetCountdownView()
      case .checkingAllowance:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle(Strings.checkingAllowance, for: .normal)
        self.errorView.isHidden = true
        self.platformTableView.isHidden = false
        self.approveGuideView.isHidden = true
        self.loadingView.isHidden = true
        self.rateLoadingView.isHidden = false
        self.loadingIndicator.end()
        self.loadingIndicator.isHidden = true
        self.resetCountdownView()
      case .notApproved:
        let sourceSymbol = self.viewModel.sourceToken.value?.symbol ?? ""
        self.continueButton.isEnabled = true
        self.continueButton.setTitle(String(format: Strings.approveToken, sourceSymbol), for: .normal)
        self.rateLoadingView.isHidden = false
        self.errorView.isHidden = true
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
        self.approveGuideLabel.attributedText = String(format: Strings.swapApproveWarn, sourceSymbol).withLineSpacing()
        self.approveGuideView.isHidden = false
      case .approving:
        let sourceSymbol = self.viewModel.sourceToken.value?.symbol ?? ""
        self.continueButton.isEnabled = false
        self.continueButton.setTitle(String(format: Strings.approvingToken, sourceSymbol), for: .normal)
        self.approveGuideLabel.attributedText = String(format: Strings.swapApproveWarn, sourceSymbol).withLineSpacing()
      case .requiredExpertMode:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle(self.titleForContinueButton, for: .normal)
        self.rateLoadingView.isHidden = false
        self.errorView.isHidden = true
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
        self.approveGuideView.isHidden = true
      case .ready:
        self.continueButton.isEnabled = true
        self.continueButton.setTitle(self.titleForContinueButton, for: .normal)
        self.rateLoadingView.isHidden = false
        self.errorView.isHidden = true
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
        self.approveGuideView.isHidden = true
      }
    }
    
    viewModel.priceImpactState.observeAndFire(on: self) { [weak self] state in
      guard let self = self else { return }
      switch state {
      case .normal:
        self.piWarningView.isHidden = true
        self.priceImpactInfoView.setValue(value: self.viewModel.priceImpactString.value ?? "", highlighted: false)
        self.priceImpactInfoView.valueLabel.textColor = .white.withAlphaComponent(0.5)
      case .high:
        self.piWarningView.backgroundColor = .Kyber.textWarningYellow.withAlphaComponent(0.1)
        self.piWarningIcon.image = Images.swapInfoYellow
        self.piWarningLabel.attributedText = Strings.swapWarnPriceImpact1.withLineSpacing()
        self.piWarningLabel.textColor = .Kyber.textWarningYellow
        self.piWarningView.isHidden = false
        self.priceImpactInfoView.setValue(value: self.viewModel.priceImpactString.value ?? "", highlighted: false)
        self.priceImpactInfoView.valueLabel.textColor = .Kyber.textWarningYellow
      case .veryHigh:
        self.piWarningView.backgroundColor = .Kyber.textWarningRed.withAlphaComponent(0.1)
        self.piWarningIcon.image = Images.swapWarningRed
        self.piWarningLabel.attributedText = Strings.swapWarnPriceImpact3.withLineSpacing()
        self.piWarningLabel.textColor = .Kyber.textWarningRed
        self.piWarningView.isHidden = false
        self.priceImpactInfoView.setValue(value: self.viewModel.priceImpactString.value ?? "", highlighted: false)
        self.priceImpactInfoView.valueLabel.textColor = .Kyber.textWarningRed
      case .veryHighNeedExpertMode:
        self.piWarningView.backgroundColor = .Kyber.textWarningRed.withAlphaComponent(0.1)
        self.piWarningIcon.image = Images.swapWarningRed
        self.piWarningLabel.attributedText = Strings.swapWarnPriceImpact2.withLineSpacing()
        self.piWarningLabel.textColor = .Kyber.textWarningRed
        self.piWarningView.isHidden = false
        self.priceImpactInfoView.setValue(value: self.viewModel.priceImpactString.value ?? "", highlighted: false)
        self.priceImpactInfoView.valueLabel.textColor = .Kyber.textWarningRed
      case .outOfNegativeRange:
        self.piWarningView.backgroundColor = .Kyber.textWarningRed.withAlphaComponent(0.1)
        self.piWarningIcon.image = Images.swapWarningRed
        self.piWarningLabel.attributedText = Strings.swapWarnPriceImpact4.withLineSpacing()
        self.piWarningLabel.textColor = .Kyber.textWarningRed
        self.piWarningView.isHidden = false
        self.priceImpactInfoView.setValue(value: self.viewModel.priceImpactString.value ?? "", highlighted: false)
        self.priceImpactInfoView.valueLabel.textColor = .Kyber.textWarningRed
      case .outOfPositiveRange:
        self.piWarningView.backgroundColor = .Kyber.textWarningRed.withAlphaComponent(0.1)
        self.piWarningIcon.image = Images.swapWarningRed
        self.piWarningLabel.attributedText = Strings.swapWarnPriceImpact5.withLineSpacing()
        self.piWarningLabel.textColor = .Kyber.textWarningRed
        self.piWarningView.isHidden = false
        self.priceImpactInfoView.setValue(value: self.viewModel.priceImpactString.value ?? "", highlighted: false)
        self.priceImpactInfoView.valueLabel.textColor = .Kyber.textWarningRed
      }
    }
    
    viewModel.souceAmountUsdString.observeAndFire(on: self) { [weak self] string in
      self?.sourceAmountUsdLabel.text = string
    }
    
    viewModel.hasPendingTransaction.observeAndFire(on: self) { [weak self] hasPendingTx in
      self?.dotView.isHidden = !hasPendingTx
    }
    
    viewModel.error.observe(on: self) { [weak self] error in
      guard let error = error else { return }
      self?.showErrorTopBannerMessage(with: error.title ?? "", message: error.message)
    }
    
    viewModel.isExpanding.observeAndFire(on: self) { [weak self] isExpanding in
      self?.expandIcon.image = isExpanding ? Images.swapPullup : Images.swapDropdown
    }
    
    viewModel.settingsObservable.observeAndFire(on: self) { [weak self] settings in
      self?.settingButton.tintColor = settings.expertModeOn ? .red : .white
    }
  }
  
  @IBAction func settingsWasTapped(_ sender: Any) {
    viewModel.openSettings()
  }
  
  @IBAction func swapPairWasTapped(_ sender: Any) {
    viewModel.swapPair()
  }
  
  @IBAction func continueWasTapped(_ sender: Any) {
    guard !KNGeneralProvider.shared.isBrowsingMode else {
      onAddWalletButtonTapped(sender)
      return
    }
    viewModel.didTapContinue()
  }
  
  @IBAction func infoExpandWasTapped(_ sender: Any) {
    self.isInfoExpanded.toggle()
  }
  
  @IBAction func historyButtonWasTapped(_ sender: Any) {
    viewModel.didTapHistoryButton()
    MixPanelManager.track("swap_history", properties: ["screenid": "swap"])
  }
  
  @objc override func onAppSwitchChain() {
    super.onAppSwitchChain()
    reloadWallet()
    viewModel.appDidSwitchChain()
  }
  
  @objc func onToggleExpand() {
    viewModel.isExpanding.value.toggle()
    viewModel.reloadPlatformRatesViewModels()
    let numberOfRows = viewModel.numberOfRateRows
    let rowsToShow = viewModel.isExpanding.value ? numberOfRows : min(2, numberOfRows)
    UIView.animate(withDuration: 0.5) {
      self.destViewHeight.constant = CGFloat(112) + CGFloat(rowsToShow) * self.platformRateItemHeight + 24
      self.view.layoutIfNeeded()
    }
  }
  
  @objc func openSourceTokenSearch() {
      TokenModule.openSearchToken(on: self) { [weak self] selectedToken in
          self?.viewModel.updateSourceToken(token: selectedToken.token)
      }
  }
  
  @objc func openDestTokenSearch() {
      TokenModule.openSearchToken(on: self) { [weak self] selectedToken in
          self?.viewModel.updateDestToken(token: selectedToken.token)
      }
  }
  
  @objc func sourceBalanceTapped() {
    guard let decimals = viewModel.sourceToken.value?.decimals else { return }
    let maxAvailableAmount = viewModel.maxAvailableSourceTokenAmount
    let allBalanceText = NumberFormatUtils.amount(value: maxAvailableAmount, decimals: decimals)
    sourceTextField.text = allBalanceText
    sourceTextField.resignFirstResponder()
    if viewModel.isSourceTokenQuote {
      showSuccessTopBannerMessage(
        message: String(format: Strings.swapSmallAmountOfQuoteTokenUsedForFee, KNGeneralProvider.shared.quoteToken)
      )
    }
    onSourceAmountChange(value: allBalanceText)
      MixPanelManager.track("swap_max_amount", properties: ["screenid": "swap"])
      MixPanelManager.track("swap_enter_amount", properties: ["screenid": "swap"])
  }
}

// MARK: Data
extension SwapV2ViewController {
  
  func reloadRates() {
    let numberOfRows = viewModel.numberOfRateRows
    let rowsToShow =  viewModel.isExpanding.value ? numberOfRows : min(2, numberOfRows)
    
    canExpand = numberOfRows > 2
    if !canExpand {
      viewModel.isExpanding.value = false
    }
    platformTableView.reloadData()
    
    if rowsToShow > 0 {
      UIView.animate(withDuration: 0.5) {
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
        self.errorView.isHidden = true
        self.destViewHeight.constant = CGFloat(112) + CGFloat(rowsToShow) * self.platformRateItemHeight + 24
        self.view.layoutIfNeeded()
      }
    } else {
      UIView.animate(withDuration: 0.5) {
        self.platformTableView.isHidden = true
        self.loadingView.isHidden = true
        if self.viewModel.isInputValid {
          self.errorView.isHidden = true
          self.destViewHeight.constant = CGFloat(112) + self.loadingViewHeight + 24
        } else {
          self.errorView.isHidden = false
          self.errorLabel.text = Strings.swapRateNotFound
          self.destViewHeight.constant = CGFloat(112)
        }
        self.view.layoutIfNeeded()
      }
    }
  }
  
  func showFetchingPlatformsAnimation() {
    loadingView.isHidden = false
  }
  
}

// MARK: Rate loading animation
extension SwapV2ViewController {

  func setupRateLoadingView() {
    rateLoadingView.isHidden = true
    remainingTime = rateReloadingInterval
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
      self?.onTimerTick()
    })
    RunLoop.main.add(timer!, forMode: .default)
    rateLoadingView.isUserInteractionEnabled = true
    let reloadRateGesture = UITapGestureRecognizer(target: self, action: #selector(onTapReloadRate))
    rateLoadingView.addGestureRecognizer(reloadRateGesture)
  }
  
  @objc func onTapReloadRate() {
    loadingIndicator.isHidden = false
    loadingIndicator.start(beginingValue: 1)
    resetCountdownView()
    viewModel.reloadRates(isRefresh: true)
  }
  
  func onTimerTick() {
    remainingTime -= 1
    if remainingTime == 0 {
      if viewModel.state.value.isActiveState {
        loadingIndicator.isHidden = false
        loadingIndicator.start(beginingValue: 1)
        resetCountdownView()
        viewModel.reloadRates(isRefresh: true)
      }
    } else {
      rateLoadingView.setRemainingTime(seconds: remainingTime)
    }
  }
  
  func resetCountdownView() {
    remainingTime = rateReloadingInterval
    rateLoadingView.setRemainingTime(seconds: remainingTime)
    rateLoadingView.startAnimation(duration: rateReloadingInterval)
    rateLoadingView.isHidden = !viewModel.isInputValid
  }
  
  func onSourceAmountChange(value: String) {
    if KNGeneralProvider.shared.isBrowsingMode {
      viewModel.sourceBalance.value = BigInt(0)
    }
    guard let doubleValue = value.toDouble() else {
      viewModel.sourceAmount.value = nil
      return
    }
    guard let sourceToken = viewModel.sourceToken.value, let sourceBalance = viewModel.sourceBalance.value else {
      return
    }
    let amountToChange = BigInt(doubleValue * pow(10.0, Double(sourceToken.decimals)))
  
    if amountToChange > viewModel.maxAvailableSourceTokenAmount && amountToChange <= sourceBalance {
      showSuccessTopBannerMessage(
        message: String(format: Strings.swapSmallAmountOfQuoteTokenUsedForFee, KNGeneralProvider.shared.quoteToken)
      )
      sourceTextField.text = NumberFormatUtils.amount(value: viewModel.maxAvailableSourceTokenAmount, decimals: sourceToken.decimals)
      viewModel.sourceAmount.value = viewModel.maxAvailableSourceTokenAmount
    } else {
      viewModel.sourceAmount.value = amountToChange
    }
    MixPanelManager.track("swap_enter_amount", properties: ["screenid": "swap"])
  }
  
  func onSelectPlatformRateAt(index: Int) {
    viewModel.selectPlatform(hint: viewModel.platformRatesViewModels.value[index].rate.hint)
  }
  
}

extension SwapV2ViewController: UITextFieldDelegate {
  
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    onSourceAmountChange(value: textField.text ?? "")
    return true
  }
  
}

extension SwapV2ViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    viewModel.isExpanding.value = false
    onSelectPlatformRateAt(index: indexPath.row)
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.platformRatesViewModels.value.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SwapV2PlatformCell.self, indexPath: indexPath)!
    cell.selectionStyle = .none
    cell.configure(viewModel: viewModel.platformRatesViewModels.value[indexPath.row])
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 96
  }
  
}

extension SwapV2ViewController: SwapSummaryViewControllerDelegate {
  
  func onSwapSummaryViewClose(selectedPlatformHint: String) {
    loadingIndicator.isHidden = false
    loadingIndicator.start(beginingValue: 1)
    viewModel.selectPlatform(hint: selectedPlatformHint)
    viewModel.reloadPlatformRatesViewModels()
    viewModel.reloadRates(isRefresh: true)
  }
  
  func onSwapSummarySubmitTransaction() {
    viewModel.updateSettings(settings: SwapTransactionSettings.getDefaultSettings())
  }
    
    func onUpdateSettings(settings: SwapTransactionSettings) {
        viewModel.updateSettings(settings: settings)
    }
}
