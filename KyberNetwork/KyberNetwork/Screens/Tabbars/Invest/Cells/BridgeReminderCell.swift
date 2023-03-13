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
  
  func updateReminderText(crossChainFee: String, miniAmount: String, maxAmount: String, minFeeString: String) {
    let reminder1 = "•  Bridge fee is \(minFeeString) & it is paid to nodes facilitating token transfer \n"
    let text = "\(reminder1)•  Minimum transfer amount is \(miniAmount) (Maximum \(maxAmount))\n•  Estimated time to transfer is 10 - 30 mins"
    let attributedString = NSMutableAttributedString(string: text)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 5
    attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
    self.reminderLabel.attributedText = attributedString
  }
    
}
