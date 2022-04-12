//
//  GameItemCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class GameItemCell: UICollectionViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!

  func configure(viewModel: GameItemCellViewModel) {
    iconImageView.loadImage(urlString: viewModel.image)
    nameLabel.text = viewModel.title
  }
  
}
