//
//  SwitchChainCell.swift
//  KyberNetwork
//
//  Created by Com1 on 28/03/2022.
//

import UIKit

class SwitchChainCell: UITableViewCell {
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var markIcon: UIImageView!
  @IBOutlet weak var chainNameLabel: UILabel!
  @IBOutlet weak var cellBackgroundView: UIView!
  @IBOutlet weak var iconHeightConstraint: NSLayoutConstraint!

  func configCell(chain: ChainType, isSelected: Bool) {
    self.chainIcon.image = chain.squareIcon()
    self.chainNameLabel.text = chain.chainName()
    self.markIcon.isHidden = !isSelected
    self.cellBackgroundView.backgroundColor = isSelected ? .Kyber.buttonBg.withAlphaComponent(0.2) : .clear
  }
}
