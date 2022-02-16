//
//  MultiSendConfirmViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 16/02/2022.
//

import UIKit

class MultiSendConfirmViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  
  let transitor = TransitionDelegate()
  
  init() {
//    self.viewModel = viewModel
    super.init(nibName: MultiSendConfirmViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }

}

extension MultiSendConfirmViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 555
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
