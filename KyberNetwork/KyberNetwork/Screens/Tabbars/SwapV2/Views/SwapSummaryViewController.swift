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
  @IBOutlet weak var sourcTokenLogo: UIImageView!
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

  init(something: String) {
    super.init(nibName: SwapSummaryViewController.className, bundle: nil)
    self.modalPresentationStyle = .fullScreen
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  func setupUI() {
    self.chainIcon.image = KNGeneralProvider.shared.currentChain.chainIcon()
    self.chainNameLabel.text = KNGeneralProvider.shared.currentChain.chainName()
    setupTokensUI()
    setupInfoViews()
  }
  
  func setupTokensUI() {
    
  }
  
  func setupInfoViews() {
    rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
    rateInfoView.setValue(value: "1 BNB = 2,419.2847632 NBT")
    
    slippageInfoView.setTitle(title: "Price Slippage", underlined: true)
    slippageInfoView.setValue(value: "0.5%", highlighted: true)

    minReceiveInfoView.setTitle(title: "Min. Received", underlined: true)
    minReceiveInfoView.setValue(value: "2,418.68393 NBT")

    gasFeeInfoView.setTitle(title: "Network Fee (est)", underlined: true)
    gasFeeInfoView.setValue(value: "$0.44 • Standard", highlighted: true)

    maxGasFeeInfoView.setTitle(title: "Max Network Fee", underlined: true)
    maxGasFeeInfoView.setValue(value: "$0.60")

    priceImpactInfoView.setTitle(title: "Price Impact", underlined: true)
    priceImpactInfoView.setValue(value: "0.012%")
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
  
  @IBAction func acceptRateChangedButtonTapped(_ sender: Any) {
    updateSuccessUI(isTxDone: true)
  }

  @IBAction func confirmSwapButtonTapped(_ sender: Any) {
    updateSuccessUI(isTxDone: false)
  }
  
}
