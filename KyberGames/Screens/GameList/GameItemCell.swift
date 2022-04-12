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

  func configure(game: Game) {
    iconImageView.loadImage(urlString: game.icon)
    nameLabel.text = game.name
  }
  
}
