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
  
  @IBOutlet weak var selectButtonTrailling: NSLayoutConstraint!
  @IBOutlet weak var arrowDownIcon: UIImageView!
  var selectTokenBlock: (() -> Void)?
  var amountChangeBlock: ((String) -> Void)?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.amountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if let amountChangeBlock = amountChangeBlock, let text = textField.text {
      amountChangeBlock(text)
    }
  }
  
  func setDisableSelectToken(shouldDisable: Bool) {
    self.amountTextField.isUserInteractionEnabled = !shouldDisable
    self.maxButton.isHidden = shouldDisable
    self.arrowDownIcon.isHidden = shouldDisable
    self.selectButtonTrailling.constant = shouldDisable ? 0 : 8
  }
    
  @IBAction func selectTokenButtonTapped(_ sender: Any) {
    if let selectTokenBlock = selectTokenBlock {
      selectTokenBlock()
    }
  }
}
