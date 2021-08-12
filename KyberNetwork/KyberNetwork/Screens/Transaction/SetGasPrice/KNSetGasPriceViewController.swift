// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import MSCircularSlider

protocol KNSetGasPriceViewControllerDelegate: class {
  // gasPrice: nil if user pressed back, chosen value if user pressed done
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?)
}

struct KNSetGasPriceViewModel {

  let gradientColors: [UIColor] = [
    UIColor.Kyber.yellow,
    UIColor.Kyber.yellowDarker,
    UIColor.Kyber.orangeDarker,
  ]

  var gasPrice: BigInt
  let estGasLimit: BigInt

  init(gasPrice: BigInt, estGasLimit: BigInt) {
    self.gasPrice = min(gasPrice, KNGasConfiguration.gasPriceMax)
    self.estGasLimit = estGasLimit
  }

  var navTitleText: String {
    return NSLocalizedString("gas.price", value: "Gas Price", comment: "")
  }

  var gasPriceText: String {
    return self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
  }

  var feeBigInt: BigInt {
    return self.gasPrice * self.estGasLimit
  }

  var feeText: String {
    return self.feeBigInt.shortString(
      units: UnitConfiguration.gasFeeUnit,
      maxFractionDigits: 6
    ) + " ETH"
  }

  var txFeeAttributedString: NSAttributedString {
    let textAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.gray,
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular),
      NSAttributedString.Key.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.darkGreen,
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular),
      NSAttributedString.Key.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: ""))  ", attributes: textAttributes))
    attributedString.append(NSAttributedString(string: self.feeText, attributes: feeAttributes))
    return attributedString
  }
}

class KNSetGasPriceViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var circleSlider: MSGradientCircularSlider!
  @IBOutlet weak var gasPriceLabel: UILabel!
  @IBOutlet weak var txFeeLabel: UILabel!

  weak var delegate: KNSetGasPriceViewControllerDelegate?
  fileprivate var viewModel: KNSetGasPriceViewModel

  init(viewModel: KNSetGasPriceViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSetGasPriceViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.containerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.25),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
  }

  fileprivate func setupUI() {
    self.containerView.rounded(radius: 4.0)
    self.navTitleLabel.text = self.viewModel.navTitleText

    let currentValue: Double = Double(self.viewModel.gasPrice / BigInt(UnitConfiguration.gasPriceUnit.rawValue))
    self.circleSlider.currentValue = currentValue
    self.circularSlider(self.circleSlider, valueChangedTo: currentValue, fromUser: false)
    self.circleSlider.delegate = self

    self.updateUI()
  }

  func updateViewModel(_ viewModel: KNSetGasPriceViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  fileprivate func updateUI() {
    if self.viewModel.gasPrice == KNGasConfiguration.gasPriceMax {
      // maximum gas price
      self.circleSlider.gradientColors = [self.viewModel.gradientColors[2], self.viewModel.gradientColors[2], self.viewModel.gradientColors[2]]
    } else {
      self.circleSlider.gradientColors = self.viewModel.gradientColors
    }
    self.circleSlider.layoutIfNeeded()
    self.gasPriceLabel.text = self.viewModel.gasPriceText
    self.txFeeLabel.attributedText = self.viewModel.txFeeAttributedString
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: nil)
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: nil)
    }
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    guard !self.viewModel.gasPrice.isZero else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.gas.price", value: "Invalid Gas Price", comment: ""),
        message: NSLocalizedString("gas.price.should.not.be.zero", value: "Gas price should not be zero", comment: "")
      )
      return
    }
    self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: self.viewModel.gasPrice)
  }
}

extension KNSetGasPriceViewController: MSCircularSliderDelegate {
  func circularSlider(_ slider: MSCircularSlider, startedTrackingWith value: Double) {
  }

  func circularSlider(_ slider: MSCircularSlider, endedTrackingWith value: Double) {
  }

  func circularSlider(_ slider: MSCircularSlider, valueChangedTo value: Double, fromUser: Bool) {
    self.viewModel.gasPrice = BigInt(ceil(value)) * BigInt(EthereumUnit.gwei.rawValue)
    self.updateUI()
  }
}
