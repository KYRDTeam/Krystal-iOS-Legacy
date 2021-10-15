//
//  ToggleTokenCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2021.
//

import UIKit

class ToggleTokenCell: UITableViewCell {
  static let kCellID: String = "ToggleTokenCell"
  var onValueChanged: ((Bool) -> Void)?
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
    
  @IBAction func onToggleButtonTapped(_ sender: UISwitch) {
    guard let onValueChanged = onValueChanged else {
      return
    }
    onValueChanged(sender.isOn)
  }
}
