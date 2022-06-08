//
//  TextFieldCell.swift
//  KyberNetwork
//
//  Created by Com1 on 22/05/2022.
//

import UIKit

class TextFieldCell: UITableViewCell {
  @IBOutlet weak var textField: UITextField!
  var textChangeBlock: ((String) -> Void)?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if let textChangeBlock = self.textChangeBlock, let text = textField.text {
      textChangeBlock(text)
    }
  }
    
}
