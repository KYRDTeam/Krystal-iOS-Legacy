//
//  EarnPoolPlatformCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit

class EarnPoolPlatformCell: UITableViewCell {
  @IBOutlet weak var apyValueLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var tvlValueLabel: UILabel!
  @IBOutlet weak var dashView: DashedLineView!
  @IBOutlet weak var platformIcon: UIImageView!
  override func awakeFromNib() {
    super.awakeFromNib()
//      self.dashView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
    
  func updateUI(platform: EarnPlatform) {
    nameLabel.text = platform.name.uppercased()
    typeLabel.text = "| \(platform.type)".uppercased()
    platformIcon.setImage(urlString: platform.logo, symbol: "")
    apyValueLabel.text = NumberFormatUtils.percent(value: platform.apy)
    tvlValueLabel.text = "$" + NumberFormatUtils.volFormat(number: platform.tvl)
  }
}
