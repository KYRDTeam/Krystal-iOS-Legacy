//
//  KNCreateWalletConfirmViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/13/20.
//

import UIKit

class KNBottomPopupViewModel {
  let title: String
  let body: String
  let firstButtonTitle: String?
  let secondButtonTitle: String
  var firstButtonAction: (() -> Void)?
  var secondButtonAction: (() -> Void)?
  var dismissAction: (() -> Void)?

  init(
    title: String,
    body: String,
    firstButtonTitle: String?,
    secondButtonTitle: String,
    firstButtonAction: (() -> Void)?,
    secondButtonAction: (() -> Void)?,
    dismissAction: (() -> Void)?
  ) {
    self.title = title
    self.body = body
    self.firstButtonTitle = firstButtonTitle
    self.secondButtonTitle = secondButtonTitle
    self.firstButtonAction = firstButtonAction
    self.secondButtonAction = secondButtonAction
    self.dismissAction = dismissAction
  }
}

class KNBottomPopupViewController: KNBaseViewController, BottomPopUpAbstract {

  @IBOutlet weak var topContraint: NSLayoutConstraint!
  let transitor = TransitionDelegate()
  @IBOutlet weak var popupBody: UILabel!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var popupTitle: UILabel!
  @IBOutlet weak var popupContentView: UIView!
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var contentView: UIView!

  let viewModel: KNBottomPopupViewModel

  init(viewModel: KNBottomPopupViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBottomPopupViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.popupTitle.text = self.viewModel.title
    self.popupBody.text = self.viewModel.body
    if let firstTitle = self.viewModel.firstButtonTitle {
      self.firstButton.setTitle(firstTitle, for: .normal)
      self.firstButton.rounded(color: UIColor.Kyber.SWButtonYellow, width: 1, radius: self.firstButton.frame.size.height / 2)
    } else {
      self.firstButton.removeFromSuperview()
      let confirmButtonLeadingContraint = NSLayoutConstraint(item: self.confirmButton, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1, constant: 38)
      self.contentView.addConstraint(confirmButtonLeadingContraint)
    }
    self.confirmButton.setTitle(self.viewModel.secondButtonTitle, for: .normal)
    self.confirmButton.rounded(radius: self.confirmButton.frame.height / 2.0)
    self.confirmButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      if let action = self.viewModel.secondButtonAction {
        action()
      }
    })
  }

  @IBAction func firstButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      if let action = self.viewModel.firstButtonAction {
        action()
      }
    })
  }

  @IBAction func tapOutSidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: {
      if let action = self.viewModel.dismissAction {
        action()
      }
    })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  // MARK: BottomPopUpAbstract
  func setTopContrainConstant(value: CGFloat) {
    self.topContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 294
  }

  func getPopupContentView() -> UIView {
    return self.popupContentView
  }
}
