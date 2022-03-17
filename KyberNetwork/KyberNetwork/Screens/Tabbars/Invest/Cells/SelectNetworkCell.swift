//
//  SelectNetworkCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/03/2022.
//

import UIKit

class SelectNetworkCell: UITableViewCell {
  static let kSelectNetworkCellID: String = "SelectNetworkCell"
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
    
}
