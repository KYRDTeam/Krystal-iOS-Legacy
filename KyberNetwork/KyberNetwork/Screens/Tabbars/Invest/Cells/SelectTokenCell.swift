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
    
  @IBAction func selectTokenButtonTapped(_ sender: Any) {
    if let selectTokenBlock = selectTokenBlock {
      selectTokenBlock()
    }
  }
}
