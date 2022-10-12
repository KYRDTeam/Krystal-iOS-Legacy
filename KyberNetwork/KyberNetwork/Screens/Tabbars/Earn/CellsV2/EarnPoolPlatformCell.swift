//
//  EarnPoolPlatformCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit

class EarnPoolPlatformCell: UITableViewCell {
  @IBOutlet weak var dashView: DashedLineView!
    override func awakeFromNib() {
      super.awakeFromNib()
//      self.dashView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
    }
    
}
