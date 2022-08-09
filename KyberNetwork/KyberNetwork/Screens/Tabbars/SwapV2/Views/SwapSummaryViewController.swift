//
//  SwapSummaryViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 09/08/2022.
//

import UIKit

class SwapSummaryViewController: KNBaseViewController {
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
    setupInfoViews()
  }
  
  func setupInfoViews() {
    rateInfoView.setTitle(title: "Rate", underlined: false)
    slippageInfoView.setTitle(title: "Price Slippage", underlined: true)
    minReceiveInfoView.setTitle(title: "Min. Received", underlined: true)
    gasFeeInfoView.setTitle(title: "Gas Fee (est)", underlined: true)
    maxGasFeeInfoView.setTitle(title: "Max Gas Fee", underlined: true)
    priceImpactInfoView.setTitle(title: "Price Impact", underlined: true)
    routeInfoView.setTitle(title: "Route", underlined: true)
  }
  
  @IBAction func acceptRateChangedButtonTapped(_ sender: Any) {
    
  }

  @IBAction func confirmSwapButtonTapped(_ sender: Any) {
  }
  
}
