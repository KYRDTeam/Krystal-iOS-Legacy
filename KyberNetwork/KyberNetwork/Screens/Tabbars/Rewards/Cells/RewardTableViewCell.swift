//
//  RewardTableViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2021.
//

import UIKit

class RewardTableViewCell: UITableViewCell {
  static let kCellID: String = "RewardTableViewCell"
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var bgView: UIView!
  var shouldRoundTopBGView = false
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }
  
  override func layoutSubviews() {
    if shouldRoundTopBGView {
      bgView.roundWithCustomCorner(corners: [.topRight, .topLeft], radius: 16)
    }
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
    
}
