//
//  SelectAppProtocolCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/05/2022.
//

import UIKit

class SelectAppProtocolCell: UITableViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tickButton: UIButton!
  @IBOutlet weak var nameLabel: UILabel!
  
  func configure(chain: ChainType, isSelected: Bool) {
    iconImageView.image = chain.chainIcon()
    nameLabel.text = chain.chainName()
    tickButton.isHidden = !isSelected
  }
  
}
