//
//  RewardDetailCell.swift
//  KyberNetwork
//
//  Created by Com1 on 13/10/2021.
//

import UIKit

class RewardDetailCell: UITableViewCell {
  static let kCellID: String = "RewardDetailCell"
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var dateTimeLabel: UILabel!
  @IBOutlet weak var sourceLabel: UILabel!
  
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
