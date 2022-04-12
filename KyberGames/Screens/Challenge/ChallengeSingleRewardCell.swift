//
//  ChallengeSingleRewardCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit

class ChallengeSingleRewardCell: UICollectionViewCell {
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var rewardLabel: UILabel!
  @IBOutlet weak var rewardDescriptionLabel: UILabel!
  @IBOutlet weak var separator: UIView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    createDashLine()
  }
  
  func createDashLine() {
    separator.clipsToBounds = true
    separator.createDashedLine(
      startPoint: .zero,
      endPoint: .init(x: 0, y: separator.bounds.maxY),
      color: .black, strokeLength: 4, gapLength: 4, width: 1
    )
  }
  
}
