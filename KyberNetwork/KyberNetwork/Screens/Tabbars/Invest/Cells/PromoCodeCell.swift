//
//  PromoCodeCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/03/2022.
//

import UIKit

class PromoCodeCell: UITableViewCell {
  @IBOutlet weak var containerView: UIView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.containerView.rounded(radius: 16)
  }
  
  
}
