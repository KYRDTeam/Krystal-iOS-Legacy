//
//  CommonBaseTokenCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/08/2022.
//

import UIKit
import Services
import Utilities

class CommonBaseTokenCell: UICollectionViewCell {
  @IBOutlet weak var tokenIcon: UIImageView!
  @IBOutlet weak var tokenLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateUI(token: Token) {
    self.tokenLabel.text = token.symbol
    if URL(string: token.logo) != nil {
      self.tokenIcon.loadImage(token.logo)
    } else {
      self.tokenIcon.image = UIImage(named: "default_token")!
    }
  }
}
