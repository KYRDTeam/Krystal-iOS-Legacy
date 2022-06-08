//
//  SelectTokenCell.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class SelectTokenCell: UITableViewCell {
  @IBOutlet weak var selectTokenButton: UIButton!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var maxButton: UIButton!
  @IBOutlet weak var balanceLabelTopContraint: NSLayoutConstraint!
  @IBOutlet weak var inputContainView: UIView!
  @IBOutlet weak var selectButtonTrailling: NSLayoutConstraint!
  @IBOutlet weak var arrowDownIcon: UIImageView!
  @IBOutlet weak var errorLabel: UILabel!
  var selectTokenBlock: (() -> Void)?
  var selectMaxBlock: (() -> Void)?
  var amountChangeBlock: ((String) -> Void)?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.amountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
    self.amountTextField.setPlaceholder(text: "0.0", color: UIColor(named: "navButtonBgColor")!)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if let amountChangeBlock = amountChangeBlock, let text = textField.text {
      amountChangeBlock(text)
    }
  }
  @IBAction func maxButtonTapped(_ sender: Any) {
    if let selectMaxBlock = self.selectMaxBlock {
      selectMaxBlock()
    }
  }
  
  func setDisableSelectToken(shouldDisable: Bool) {
    self.amountTextField.isUserInteractionEnabled = !shouldDisable
    self.maxButton.isHidden = shouldDisable
    self.arrowDownIcon.isHidden = shouldDisable
    self.selectButtonTrailling.constant = shouldDisable ? 0 : 8
    self.selectTokenButton.isUserInteractionEnabled = !shouldDisable
  }
  
  func showErrorIfNeed(errorMsg: String?) {
    if let errorMsg = errorMsg {
      self.errorLabel.text = errorMsg
      self.balanceLabelTopContraint.constant = 35
      self.errorLabel.isHidden = false
      self.inputContainView.shakeViewError()
    } else {
      self.inputContainView.layer.borderColor = UIColor.clear.cgColor
      self.inputContainView.layer.borderWidth = 1.0
      self.balanceLabelTopContraint.constant = 12
      self.errorLabel.isHidden = true
    }
  }
    
  @IBAction func selectTokenButtonTapped(_ sender: Any) {
    if let selectTokenBlock = selectTokenBlock {
      selectTokenBlock()
    }
  }
}
