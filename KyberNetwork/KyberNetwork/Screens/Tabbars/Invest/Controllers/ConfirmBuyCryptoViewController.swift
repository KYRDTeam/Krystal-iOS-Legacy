//
//  ConfirmBuyCryptoViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 25/02/2022.
//

import UIKit

class ConfirmBuyCryptoViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var outSideBackgroundView: UIView!
  
  @IBOutlet weak var cryptoLabel: UILabel!
  @IBOutlet weak var fiatLabel: UILabel!
  @IBOutlet weak var networkLabel: UILabel!
  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var walletAddress: UILabel!
  @IBOutlet weak var fiatIcon: UIImageView!
  @IBOutlet weak var cryptoIcon: UIImageView!
  @IBOutlet weak var timeLabel: UILabel!

  let transitor = TransitionDelegate()
  let currentOrder: BifinityOrder
  override func viewDidLoad() {
    super.viewDidLoad()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.outSideBackgroundView.addGestureRecognizer(tapGesture)
    self.setupUI()
  }

  func setupUI() {
    self.cryptoIcon.setImage(with: self.currentOrder.cryptoLogo, placeholder: UIImage(named: "default_token"))
    self.fiatIcon.setImage(with: self.currentOrder.fiatLogo, placeholder: UIImage(named: "default_token"))
    self.cryptoLabel.text = "\(self.currentOrder.orderAmount * self.currentOrder.executePrice) \(self.currentOrder.cryptoCurrency)"
    self.fiatLabel.text = "\(self.currentOrder.orderAmount) \(self.currentOrder.fiatCurrency)"
    self.networkLabel.text = self.currentOrder.cryptoNetwork
    self.rateLabel.text = "1 \(self.currentOrder.cryptoCurrency) = \(self.currentOrder.executePrice) \(self.currentOrder.fiatCurrency)"
    self.walletAddress.text = self.currentOrder.cryptoAddress
    // createdTime get from api in milisecond
    let date = Date(timeIntervalSince1970: TimeInterval(self.currentOrder.createdTime/1000))
    self.timeLabel.text = DateFormatterUtil.shared.rewardDateTimeFormatter.string(from: date)
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }

  init(currentOrder: BifinityOrder) {
    self.currentOrder = currentOrder
    super.init(nibName: ConfirmBuyCryptoViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction func backToHomeButtonTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func gotItButtonTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension ConfirmBuyCryptoViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 420
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
