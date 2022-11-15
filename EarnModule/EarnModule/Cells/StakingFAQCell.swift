//
//  StakingFAQCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/11/2022.
//

import UIKit

class StakingFAQCell: UITableViewCell {
  
  @IBOutlet weak var contentTextView: UITextView!
  @IBOutlet weak var contentTextViewHeightContraint: NSLayoutConstraint!
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    contentTextView.linkTextAttributes = [.foregroundColor: UIColor(hex: "1DE9B6"), .underlineColor: UIColor.clear]
  }
  
  func updateContent(_ text: String) {
    contentTextView.text = text
    contentTextView.sizeToFit()
    contentTextViewHeightContraint.constant = contentTextView.contentSize.height
  }
  
  func updateHTMLContent(_ text: String) {
    
    contentTextView.attributedText = text.htmlAttributedString(size: 14)
    contentTextView.sizeToFit()
    contentTextViewHeightContraint.constant = contentTextView.contentSize.height
  }
}
