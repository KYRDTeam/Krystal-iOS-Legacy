//
//  ChallengeTaskCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import UIKit

class ChallengeTaskCell: UITableViewCell {
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var rewardLabel: UILabel!
  @IBOutlet weak var actionButton: UIButton!
  @IBOutlet weak var separator: UIView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    separator.clipsToBounds = true
    separator.createDashedLine(
      startPoint: .zero,
      endPoint: .init(x: frame.size.width, y: 0),
      color: .black,
      strokeLength: 4, gapLength: 4, width: 1)
    
  }
  
  func configure(task: ChallengeTask) {
    iconImageView.image = task.type.icon
    titleLabel.text = task.title
    descriptionLabel.text = task.description
    actionButton.setTitle(task.type.action, for: .normal)
    rewardLabel.text = "+\(task.turns) turn"
  }
  
  @IBAction func actionWasTapped(_ sender: Any) {
    
  }
  
}
