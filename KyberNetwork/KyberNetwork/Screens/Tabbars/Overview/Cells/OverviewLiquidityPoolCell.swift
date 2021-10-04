//
//  OverviewLiquidityPoolCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/10/2021.
//

import UIKit

class OverviewLiquidityPoolCell: UITableViewCell {
  static let kCellID: String = "OverviewLiquidityPoolCell"
  static let kCellHeight: CGFloat = 85
  @IBOutlet weak var cellBackgroundView: UIView!
  
  @IBOutlet weak var firstTokenIcon: UIImageView!
  
  @IBOutlet weak var secondTokenIcon: UIView!
  @IBOutlet weak var firstTokenValueLabel: UILabel!
  @IBOutlet weak var secondTokenValueLabel: UILabel!
  @IBOutlet weak var percentLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
