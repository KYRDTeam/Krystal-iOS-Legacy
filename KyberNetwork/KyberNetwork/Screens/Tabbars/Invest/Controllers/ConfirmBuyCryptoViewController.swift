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
  let transitor = TransitionDelegate()

  override func viewDidLoad() {
    super.viewDidLoad()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.outSideBackgroundView.addGestureRecognizer(tapGesture)
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }

  init() {
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
