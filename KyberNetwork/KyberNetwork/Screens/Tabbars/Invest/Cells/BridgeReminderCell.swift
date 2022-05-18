//
//  BridgeReminderCell.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class BridgeReminderCell: UITableViewCell {
  @IBOutlet weak var dashView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.dashView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
    
}
