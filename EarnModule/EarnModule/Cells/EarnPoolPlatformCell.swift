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
    func showWarning(_ type: String)
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
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var platformContainerView: UIView!
    
    
    var platform: EarnPlatform?
  weak var delegate: EarnPoolPlatformCellDelegate?
    

  override func awakeFromNib() {
    super.awakeFromNib()
      rewardApyIcon.isUserInteractionEnabled = true
      rewardApyIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRewardApyIcon)))
      
      platformContainerView.isUserInteractionEnabled = true
      platformContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPlatformContainerView)))
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
      let totalApy = platform.apy + platform.rewardApy
    apyValueLabel.text = NumberFormatUtils.percent(value: totalApy)
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
          plusButton.isHidden = true
      case "warning":
          typeLabelTrailingContraint.priority = UILayoutPriority(250)
          typeLabelSpaceWithWarningIcon.priority = UILayoutPriority(999)
          warningIconImageView.isHidden = false
          let yellow = UIColor(hex: "F2BE37")
          warningIconImageView.tintColor = yellow
          plusButton.isHidden = false
      default:
          typeLabelTrailingContraint.priority = UILayoutPriority(999)
          typeLabelSpaceWithWarningIcon.priority = UILayoutPriority(250)
          warningIconImageView.isHidden = true
          plusButton.isHidden = false
      }
  }
    
    @objc func tapRewardApyIcon() {
        guard let platform = platform else {
            return
        }

        delegate?.didSelectRewardApy(platform)
    }
    
    @objc func tapPlatformContainerView() {
        guard let platform = platform else {
            return
        }
        
        switch platform.status.lowercased() {
        case "disabled":
            delegate?.showWarning("disabled")
        case "warning":
            delegate?.showWarning("warning")
        default:
            break
        }
    }
}
