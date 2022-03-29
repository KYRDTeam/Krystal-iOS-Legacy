//
//  SwitchChainCell.swift
//  KyberNetwork
//
//  Created by Com1 on 28/03/2022.
//

import UIKit

class SwitchChainCell: UITableViewCell {
  static let kCellID: String = "SwitchChainCell"
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var markIcon: UIImageView!
  @IBOutlet weak var chainNameLabel: UILabel!
  @IBOutlet weak var cellBackgroundView: UIView!
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
  
  func configCell(chain: ChainType, isSelected: Bool) {
    self.chainIcon.image = chain.chainIcon()
    self.chainNameLabel.text = chain.chainName()
    self.markIcon.isHidden = !isSelected
    self.cellBackgroundView.backgroundColor = isSelected ? UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2) : .clear
  }
    
}
