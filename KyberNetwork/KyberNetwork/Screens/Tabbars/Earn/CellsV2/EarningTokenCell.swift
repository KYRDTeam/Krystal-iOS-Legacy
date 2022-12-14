//
//  EarningTokenCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 28/10/2022.
//

import UIKit

class EarningTokenCell: UICollectionViewCell {

  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenDescLabel: UILabel!
  
  func updateCell(_ data: EarningToken, selected: Bool) {
    tokenIconImageView.setImage(urlString: data.logo, symbol: data.symbol)
    tokenNameLabel.text = data.symbol
    tokenDescLabel.text = data.desc
    
    if selected {
      rounded(color: UIColor.Kyber.buttonBg, width: 1, radius: 12)
    } else {
      rounded(radius: 12)
    }
  }
}
