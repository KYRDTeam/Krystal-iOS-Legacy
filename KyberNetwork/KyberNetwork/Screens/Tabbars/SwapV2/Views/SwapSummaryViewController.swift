//
//  SwapSummaryViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 09/08/2022.
//

import UIKit
import BigInt

protocol SwapSummaryViewControllerDelegate: AnyObject {
  func onSwapSummaryViewClose()
}

class SwapSummaryViewController: KNBaseViewController {
  @IBOutlet weak var chainNameLabel: UILabel!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var rateChangedView: UIView!
  @IBOutlet weak var signSuccessView: UIView!
  @IBOutlet weak var errorView: UIView!
  @IBOutlet weak var rateInfoView: SwapInfoView!
  @IBOutlet weak var slippageInfoView: SwapInfoView!
  @IBOutlet weak var minReceiveInfoView: SwapInfoView!
  @IBOutlet weak var gasFeeInfoView: SwapInfoView!
  @IBOutlet weak var maxGasFeeInfoView: SwapInfoView!
  @IBOutlet weak var priceImpactInfoView: SwapInfoView!
  @IBOutlet weak var sourceTokenLogo: UIImageView!
  @IBOutlet weak var sourceTokenSymbolLabel: UILabel!
  @IBOutlet weak var sourceTokenBalanceLabel: UILabel!
  @IBOutlet weak var sourceTokenValueLabel: UILabel!
  @IBOutlet weak var destTokenLogo: UIImageView!
  @IBOutlet weak var destTokenSymbolLabel: UILabel!
  @IBOutlet weak var destTokenBalanceLabel: UILabel!
  @IBOutlet weak var destTokenValueLabel: UILabel!
  @IBOutlet weak var stackViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var confirmSwapButton: UIButton!
  @IBOutlet weak var confirmSwapButtonTopConstraint: NSLayoutConstraint!
  var viewModel: SwapSummaryViewModel

  weak var delegate: SwapSummaryViewControllerDelegate?
  
  init(viewModel: SwapSummaryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SwapSummaryViewController.className, bundle: nil)
    self.modalPresentationStyle = .fullScreen
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    self.viewModel.updateData()
    self.viewModel.startUpdateRate()
  }
  
  func setupUI() {
    self.chainIcon.image = KNGeneralProvider.shared.currentChain.chainIcon()
    self.chainNameLabel.text = KNGeneralProvider.shared.currentChain.chainName()
    setupTokensUI()
    setupInfoViews()
    bindViewModel()
  }
  
  func setupTokensUI() {
    if let url = URL(string: viewModel.swapObject.sourceToken.logo) {
      sourceTokenLogo.setImage(with: url, placeholder: UIImage(named: "default_token")!)
    } else {
      sourceTokenLogo.image = UIImage(named: "default_token")!
    }
    sourceTokenValueLabel.text = viewModel.getSourceAmountUsdString()
    sourceTokenSymbolLabel.text = viewModel.swapObject.sourceToken.symbol
    sourceTokenBalanceLabel.text = viewModel.swapObject.sourceAmount.shortString(decimals: viewModel.swapObject.sourceToken.decimals)
    
    if let url = URL(string: viewModel.swapObject.destToken.logo) {
      destTokenLogo.setImage(with: url, placeholder: UIImage(named: "default_token")!)
    } else {
      destTokenLogo.image = UIImage(named: "default_token")!
    }
    destTokenValueLabel.text = viewModel.getDestAmountUsdString()
    destTokenBalanceLabel.text = viewModel.getDestAmountString()
    destTokenSymbolLabel.text = viewModel.swapObject.destToken.symbol
  }
  
  func bindViewModel() {
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
    
    viewModel.priceImpactString.observeAndFire(on: self) { [weak self] string in
      self?.priceImpactInfoView.setValue(value: string, highlighted: false)
    }
    
    viewModel.maxGasFeeString.observeAndFire(on: self) { [weak self] string in
      self?.maxGasFeeInfoView.setValue(value: string, highlighted: false)
    }
    
    viewModel.newRate.observeAndFire(on: self) { [weak self] _ in
      self?.updateRateChangedViewUI(rateChanged: self?.viewModel.newRate.value != nil)
    }
    
    viewModel.internalHistoryTransaction.observeAndFire(on: self) { [weak self] pendingTransaction in
      if let pendingTransaction = pendingTransaction {
        let controller = SwapProcessPopup(transaction: pendingTransaction)
        controller.delegate = self
        self?.present(controller, animated: true, completion: nil)
      }
    }
    
    viewModel.shouldDiplayLoading.observeAndFire(on: self) { [weak self] shouldDisplay in
      if let shouldDisplay = shouldDisplay {
        if shouldDisplay {
          self?.showLoadingHUD()
        } else {
          self?.hideLoading(animated: false)
        }
      }
    }
  }
  
  func setupInfoViews() {
    rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
    rateInfoView.onTapRightIcon = { [weak self] in
      self?.viewModel.showRevertedRate.toggle()
    }
    
    slippageInfoView.setTitle(title: "Max Slippage", underlined: true)
    slippageInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapSlippageInfo, icon: Images.swapInfo)
    }
    slippageInfoView.onTapValue = { [weak self] in
      if let gasLimit = self?.viewModel.gasLimit, let settings = self?.viewModel.swapObject.swapSetting {
        self?.openTransactionSettings(gasLimit: gasLimit, settings: settings)
      }
    }

    minReceiveInfoView.setTitle(title: "Min. Received", underlined: true)
    minReceiveInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapMinReceiveInfo, icon: Images.swapInfo)
    }

    gasFeeInfoView.setTitle(title: "Network Fee (est)", underlined: true)
    gasFeeInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapTxnFeeInfo, icon: Images.swapInfo)
    }
    gasFeeInfoView.onTapValue = { [weak self] in
      if let gasLimit = self?.viewModel.gasLimit, let settings = self?.viewModel.swapObject.swapSetting {
        self?.openTransactionSettings(gasLimit: gasLimit, settings: settings)
      }
    }

    maxGasFeeInfoView.setTitle(title: "Max Network Fee", underlined: true)
    maxGasFeeInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapTxnMaxFeeInfo, icon: Images.swapInfo)
    }

    priceImpactInfoView.setTitle(title: "Price Impact", underlined: true)
    priceImpactInfoView.onTapTitle = { [weak self] in
      self?.showBottomBannerView(message: Strings.swapPriceImpactInfo, icon: Images.swapInfo)
    }
  }
  
  func updateErrorUI(isTxFailed: Bool) {
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) { [self] in
      self.errorView.isHidden = !isTxFailed
      self.confirmSwapButtonTopConstraint.constant = isTxFailed ? 165 : 85
      self.view.layoutIfNeeded()
    }
  }
  
  func updateSuccessUI(isTxDone: Bool) {
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) { [self] in
      self.signSuccessView.isHidden = !isTxDone
      self.confirmSwapButton.isHidden = isTxDone
      self.confirmSwapButtonTopConstraint.constant = isTxDone ? 165 : 85
      self.view.layoutIfNeeded()
    }
  }
  
  func updateRateChangedViewUI(rateChanged: Bool) {
    if rateChanged {
      self.confirmSwapButton.isEnabled = false
      self.confirmSwapButton.setBackgroundColor(UIColor(named: "navButtonBgColor")!, forState: .disabled)
    } else {
      self.confirmSwapButton.isEnabled = true
      self.confirmSwapButton.setBackgroundColor(UIColor(named: "buttonBackgroundColor")!, forState: .normal)
    }
    
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) { [self] in
      self.rateChangedView.isHidden = !rateChanged
      self.stackViewTopConstraint.constant = rateChanged ? 86 : 26
      self.view.layoutIfNeeded()
    }
  }
  
  @IBAction func acceptRateChangedButtonTapped(_ sender: Any) {
    viewModel.updateRate()
    destTokenBalanceLabel.text = viewModel.getDestAmountString()
    destTokenValueLabel.text = viewModel.getDestAmountUsdString()
  }

  @IBAction func confirmSwapButtonTapped(_ sender: Any) {
    viewModel.didConfirmSwap()
  }
  
  @IBAction func onCloseButtonTapped(_ sender: Any) {
    delegate?.onSwapSummaryViewClose()
    self.dismiss(animated: true)
  }
  
  func openTransactionSettings(gasLimit: BigInt, settings: SwapTransactionSettings) {
    let selectedGasPriceType: KNSelectedGasPriceType = {
      if let basic = settings.basic {
        return basic.gasPriceType
      }
      return .custom
    }()
    
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: selectedGasPriceType, currentRatePercentage: settings.slippage, isUseGasToken: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    viewModel.advancedGasLimit = (settings.advanced?.gasLimit).map(String.init)
    viewModel.advancedMaxPriorityFee = (settings.advanced?.maxPriorityFee).map {
      return NumberFormatUtils.format(value: $0, decimals: 9, maxDecimalMeaningDigits: 2, maxDecimalDigits: 2)
    }
    viewModel.advancedMaxFee = (settings.advanced?.maxFee).map {
      return NumberFormatUtils.format(value: $0, decimals: 9, maxDecimalMeaningDigits: 2, maxDecimalDigits: 2)
    }
    viewModel.advancedNonce = (settings.advanced?.nonce).map { "\($0)" }

    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.present(vc, animated: true, completion: nil)
  }
}

extension SwapSummaryViewController: GasFeeSelectorPopupViewControllerDelegate {
  
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, _):
      self.viewModel.updateGasPriceType(type: type)
      
    case .minRatePercentageChanged(let percent):
      self.viewModel.updateSlippage(slippage: percent)
      
    case .updateAdvancedSetting(let gasLimit, let maxPriorityFee, let maxFee):
      guard let gasLimit = BigInt(gasLimit), let maxFee = maxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit), let maxPriorityFee = maxPriorityFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) else {
        return
      }
      self.viewModel.updateAdvancedFee(maxFee: maxFee, maxPriorityFee: maxPriorityFee, gasLimit: gasLimit)
      
    case .updateAdvancedNonce(let nonce):
      guard let nonce = Int(nonce) else { return }
      self.viewModel.updateAdvancedNonce(nonce: nonce)
      
    default:
      return
    }
  }
  
}

extension SwapSummaryViewController: SwapProcessPopupDelegate {
  func swapProcessPopup(_ controller: SwapProcessPopup, action: SwapProcessPopupEvent) {
    controller.dismiss(animated: true) {
      switch action {
      case .openLink(let url):
        self.openSafari(with: url)
      case .goToSupport:
        self.openSafari(with: Constants.supportURL)
      case .viewToken(let sym):
        if let token = KNSupportedTokenStorage.shared.getTokenWith(symbol: sym) {
          self.dismiss(animated: false) {
            AppDelegate.shared.coordinator.exchangeTokenCoordinatorDidSelectTokens(token: token)
          }
        }
      case .close:
        self.dismiss(animated: true)
      }
    }
  }
}
