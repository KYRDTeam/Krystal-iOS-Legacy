//
//  ExpertModeWarningViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/08/2022.
//

import UIKit
import BaseModule
import DesignSystem

class ExpertModeWarningViewController: KNBaseViewController {
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var confirmTextField: UITextField!
  
  var confirmAction: (Bool) -> Void = { _ in }
  
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
      let customizedText = NSMutableAttributedString(string: Strings.advancedModeWarningText)
      customizedText.addAttribute(.font, value: UIFont.karlaReguler(ofSize: 14),
                                  range: NSRange(location: 0, length: Strings.advancedModeWarningText.count))
      customizedText.addAttribute(NSAttributedString.Key.foregroundColor,
                                  value: AppTheme.current.errorTextColor,
                                  range: NSRange(location: 0, length: "Expert Mode".count))
    messageLabel.attributedText = customizedText
    
      self.confirmTextField.attributedPlaceholder = NSAttributedString(string: "Confirm", attributes: [NSAttributedString.Key.foregroundColor: AppTheme.current.placeholderTextColor])
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
