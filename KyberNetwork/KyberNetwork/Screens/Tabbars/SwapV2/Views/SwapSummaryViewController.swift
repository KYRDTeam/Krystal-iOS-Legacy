//
//  SwapSummaryViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 09/08/2022.
//

import UIKit

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
  @IBOutlet weak var routeInfoView: SwapInfoView!
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
    self.viewModel.updateData(controller: self)
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
    sourceTokenSymbolLabel.text = viewModel.swapObject.sourceToken.symbol
    sourceTokenBalanceLabel.text = viewModel.swapObject.sourceAmount.shortString(decimals: viewModel.swapObject.sourceToken.decimals)
    
    if let url = URL(string: viewModel.swapObject.destToken.logo) {
      destTokenLogo.setImage(with: url, placeholder: UIImage(named: "default_token")!)
    } else {
      destTokenLogo.image = UIImage(named: "default_token")!
    }
    destTokenSymbolLabel.text = viewModel.swapObject.destToken.symbol
    destTokenBalanceLabel.text = viewModel.swapObject.sourceAmount.shortString(decimals: viewModel.swapObject.sourceToken.decimals)
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
  }
  
  func setupInfoViews() {
    rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
    rateInfoView.onTapRightIcon = { [weak self] in
      self?.viewModel.showRevertedRate.toggle()
    }
    
    slippageInfoView.setTitle(title: "Price Slippage", underlined: true)

    minReceiveInfoView.setTitle(title: "Min. Received", underlined: true)

    gasFeeInfoView.setTitle(title: "Network Fee (est)", underlined: true)

    maxGasFeeInfoView.setTitle(title: "Max Network Fee", underlined: true)

    priceImpactInfoView.setTitle(title: "Price Impact", underlined: true)
    routeInfoView.setTitle(title: "Route", underlined: true)
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
  
  func rateUpdated(newRate: String, priceImpact: Int) {
    updateRateChangedViewUI(rateChanged: true)
    var currentRate = viewModel.swapObject.rate
    currentRate.rate = newRate
    currentRate.priceImpact = priceImpact
    viewModel.newRate = currentRate
  }
  
  @IBAction func acceptRateChangedButtonTapped(_ sender: Any) {
    updateRateChangedViewUI(rateChanged: false)
    viewModel.updateRate()
  }

  @IBAction func confirmSwapButtonTapped(_ sender: Any) {
    
  }
  
  @IBAction func onCloseButtonTapped(_ sender: Any) {
    self.dismiss(animated: true)
  }
}
