//
//  BridgeReminderCell.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class BridgeReminderCell: UITableViewCell {
  @IBOutlet weak var dashView: UIView!
  @IBOutlet weak var reminderLabel: UILabel!
  override func awakeFromNib() {
    super.awakeFromNib()
    self.dashView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
  
  func updateReminderText(crossChainFee: String, gasFeeString: String, miniAmount: String, maxAmount: String, thresholdString: String) {
    self.reminderLabel.text = "Crosschain Fee is \(crossChainFee) %, Gas fee \(gasFeeString) for your cross-chain transaction on destination chain. Minimum Crosschain Amount is \(miniAmount). Maximum Crosschain Amount is \(maxAmount). Estimated Time of Crosschain Arrival is 10-30 min. Crosschain amount larger than \(thresholdString) could take up to 12 hours."
  }
    
}
