//
//  ExpertModeWarningViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/08/2022.
//

import UIKit

class ExpertModeWarningViewController: KNBaseViewController {
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var confirmTextField: UITextField!
  
  var confirmAction: (Bool) -> Void = { _ in }
  let transitor = TransitionDelegate()
  
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  
  init() {
    super.init(nibName: ExpertModeWarningViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let customizedText = NSMutableAttributedString(string: Strings.advancedModeWarningText)
    
    customizedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.Kyber.textWarningRed, range: NSRange(location: 0, length: "Expert Mode".count))
    messageLabel.attributedText = customizedText
    
    self.confirmTextField.attributedPlaceholder = NSAttributedString(string: "Confirm", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    if confirmTextField.text?.lowercased() == "confirm".lowercased() {
      dismiss(animated: true) {
        self.confirmAction(true)
      }
    } else {
      self.showErrorTopBannerMessage(message: "Please type the word ‘confirm’ below to enable Expert Mode.")
    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    dismiss(animated: true) {
      self.confirmAction(false)
    }
  }
}

extension ExpertModeWarningViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 454
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
