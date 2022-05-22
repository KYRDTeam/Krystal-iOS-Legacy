//
//  BridgeSendToCell.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class BridgeSendToCell: UITableViewCell {
  @IBOutlet weak var icon: UIImageView!
  var sendButtonTapped: (() -> Void)?
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
    
  @IBAction func onSendToButtonTapped(_ sender: Any) {
    if let sendButtonTapped = self.sendButtonTapped {
      sendButtonTapped()
    }
  }
}
