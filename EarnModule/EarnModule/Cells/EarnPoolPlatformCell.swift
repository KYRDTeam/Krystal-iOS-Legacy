//
//  EarnPoolPlatformCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit
import DesignSystem
import Utilities
import Services

protocol EarnPoolPlatformCellDelegate: class {
  func didSelectStake(_ platform: EarnPlatform)
    func didSelectRewardApy(_ platform: EarnPlatform)
}

class EarnPoolPlatformCell: UITableViewCell {
  @IBOutlet weak var apyValueLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var tvlValueLabel: UILabel!
  @IBOutlet weak var dashView: DashedLineView!
  @IBOutlet weak var platformIcon: UIImageView!
    @IBOutlet weak var rewardApyIcon: UIImageView!
    @IBOutlet weak var warningIconImageView: UIImageView!
    @IBOutlet weak var typeLabelTrailingContraint: NSLayoutConstraint!
    @IBOutlet weak var typeLabelSpaceWithWarningIcon: NSLayoutConstraint!
    
    var platform: EarnPlatform?
  weak var delegate: EarnPoolPlatformCellDelegate?
    

  override func awakeFromNib() {
    super.awakeFromNib()
      rewardApyIcon.isUserInteractionEnabled = true
      rewardApyIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRewardApyIcon)))
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  @IBAction func plusButtonTapped(_ sender: UIButton) {
      if let unwrap = platform {
        delegate?.didSelectStake(unwrap)
    }
  }
    
  func updateUI(platform: EarnPlatform) {
    nameLabel.text = platform.name.uppercased()
    typeLabel.text = "| \(platform.type)".capitalized
    platformIcon.setImage(urlString: platform.logo, symbol: "")
    apyValueLabel.text = NumberFormatUtils.percent(value: platform.apy)
    tvlValueLabel.text = "$" + NumberFormatUtils.volFormat(number: platform.tvl)
    self.platform = platform
      let hasRewardApy = platform.rewardApy > 0
      rewardApyIcon.isHidden = !hasRewardApy
      
      switch platform.status.lowercased() {
      case "disabled":
          typeLabelTrailingContraint.priority = UILayoutPriority(250)
          typeLabelSpaceWithWarningIcon.priority = UILayoutPriority(999)
          warningIconImageView.isHidden = false
          let red = UIColor(hex: "F45532")
          warningIconImageView.tintColor = red
      case "warning":
          typeLabelTrailingContraint.priority = UILayoutPriority(250)
          typeLabelSpaceWithWarningIcon.priority = UILayoutPriority(999)
          warningIconImageView.isHidden = false
          let yellow = UIColor(hex: "F2BE37")
          warningIconImageView.tintColor = yellow
      default:
          typeLabelTrailingContraint.priority = UILayoutPriority(999)
          typeLabelSpaceWithWarningIcon.priority = UILayoutPriority(250)
          warningIconImageView.isHidden = true
      }
  }
    
    @objc func tapRewardApyIcon() {
        guard let platform = platform else {
            return
        }

        delegate?.didSelectRewardApy(platform)
    }
}
