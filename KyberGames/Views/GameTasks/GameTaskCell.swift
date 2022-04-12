//
//  GameTaskCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import UIKit

class GameTaskCell: UITableViewCell {
  
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
  
  func configure(viewModel: GameTaskCellViewModel) {
    iconImageView.image = viewModel.image
    titleLabel.text = viewModel.title
    descriptionLabel.text = viewModel.description
    actionButton.setTitle(viewModel.action, for: .normal)
    rewardLabel.text = viewModel.rewardString
  }
  
  @IBAction func actionWasTapped(_ sender: Any) {
    
  }
  
}
