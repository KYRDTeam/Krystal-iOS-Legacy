//
//  RateTransactionPopupViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 09/03/2022.
//

import UIKit

class RateTransactionPopupViewController: KNBaseViewController {
  @IBOutlet weak var oneStarButton: UIButton!
  @IBOutlet weak var twoStarButton: UIButton!
  @IBOutlet weak var threeStarButton: UIButton!
  @IBOutlet weak var fourStarButton: UIButton!
  @IBOutlet weak var fiveStarButton: UIButton!
  @IBOutlet weak var detailTextView: UITextView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var tapOutsideBGView: UIView!
  @IBOutlet weak var finishView: UIView!
  @IBOutlet weak var doneImageView: UIImageView!
  @IBOutlet weak var sendButton: UIButton!
  var currentRate: Int
  var detailValuation: String?
  let transitor = TransitionDelegate()
  init(currentRate: Int) {
    self.currentRate = currentRate
    super.init(nibName: RateTransactionPopupViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
      super.viewDidLoad()

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.tapOutsideBGView.addGestureRecognizer(tapGesture)
    self.updateRateUI(rate: self.currentRate)
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func rateButtonTapped(_ sender: UIButton) {
    self.updateRateUI(rate: sender.tag)
  }

  @IBAction func closeButtonTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func sendButtonTapped(_ sender: Any) {
    self.finishView.isHidden = false
  }
  
  func updateRateUI(rate: Int) {
    self.sendButton.isEnabled = rate > 3
    self.oneStarButton.setImage(rate >= 1 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.oneStarButton.setImage(rate >= 1 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)

    self.twoStarButton.setImage(rate >= 2 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.twoStarButton.setImage(rate >= 2 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)

    self.threeStarButton.setImage(rate >= 3 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.threeStarButton.setImage(rate >= 3 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)

    self.fourStarButton.setImage(rate >= 4 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.fourStarButton.setImage(rate >= 4 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)

    self.fiveStarButton.setImage(rate >= 5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.fiveStarButton.setImage(rate >= 5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)
  }

}

extension RateTransactionPopupViewController: UITextViewDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    print("asd")
  }
}

extension RateTransactionPopupViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 490
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
