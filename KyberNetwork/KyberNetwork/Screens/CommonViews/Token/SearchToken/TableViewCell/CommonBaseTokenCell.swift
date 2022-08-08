//
//  CommonBaseTokenCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/08/2022.
//

import UIKit

class CommonBaseTokenCell: UICollectionViewCell {
  @IBOutlet weak var tokenIcon: UIImageView!
  @IBOutlet weak var tokenLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateUI(token: Token) {
    self.tokenLabel.text = token.symbol
    if let url = URL(string: token.logo) {
      self.tokenIcon.setImage(with: url, placeholder: UIImage(named: "default_token")!)
    } else {
      self.tokenIcon.image = UIImage(named: "default_token")!
    }
  }
}
