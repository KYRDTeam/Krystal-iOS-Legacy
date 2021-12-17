//
//  ReferralTiersCell.swift
//  KyberNetwork
//
//  Created by Com1 on 15/12/2021.
//

import UIKit

class ReferralTiersCell: UITableViewCell {

  @IBOutlet weak var levelLabel: UILabel!
  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var rewardLabel: UILabel!
  
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
    
}
