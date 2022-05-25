//
//  MiniAppReviewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 25/05/2022.
//

import UIKit

class MiniAppReviewCell: UITableViewCell {
  @IBOutlet weak var fiveStarButton: UIButton!
  @IBOutlet weak var fourStarButton: UIButton!
  @IBOutlet weak var threeStarButton: UIButton!
  @IBOutlet weak var twoStarButton: UIButton!
  @IBOutlet weak var oneStarButton: UIButton!
  @IBOutlet weak var reviewLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
  
  func updateRateUI(rate: Double) {
    self.oneStarButton.configStarRate(isHighlight: rate >= 0.5)
    self.twoStarButton.configStarRate(isHighlight: rate >= 1.5)
    self.threeStarButton.configStarRate(isHighlight: rate >= 2.5)
    self.fourStarButton.configStarRate(isHighlight: rate >= 3.5)
    self.fiveStarButton.configStarRate(isHighlight: rate >= 4.5)
  }
}
