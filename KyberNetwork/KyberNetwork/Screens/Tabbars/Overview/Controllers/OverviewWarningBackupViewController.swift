//
//  OverviewWarningBackupViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 22/10/2021.
//

import UIKit

class OverviewWarningBackupViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var backupButton: UIButton!
  @IBOutlet weak var alreadyButton: UIButton!
  @IBOutlet weak var laterButton: UIButton!

  let transitor = TransitionDelegate()
  let backupAction:  (() -> Void)
  let alreadyAction: (() -> Void)
  
  init(backupAction: @escaping (() -> Void), alreadyAction: @escaping (() -> Void)) {
    self.backupAction = backupAction
    self.alreadyAction = alreadyAction
    super.init(nibName: OverviewWarningBackupViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded()
    self.backupButton.rounded(radius: 16)
    self.alreadyButton.rounded(radius: 16)
    self.laterButton.rounded(radius: 16)
  }

  @IBAction func tapOutsidePopUp(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true)
  }
  
  @IBAction func backupButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      self.backupAction()
    })
  }

  @IBAction func alreadyButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      self.alreadyAction()
    })
  }
  
  @IBAction func laterButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension OverviewWarningBackupViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 370
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
