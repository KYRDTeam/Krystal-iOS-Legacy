//
//  MiniAppDetailCell.swift
//  KyberNetwork
//
//  Created by Com1 on 24/05/2022.
//

import UIKit

class MiniAppDetailCell: UITableViewCell {
  @IBOutlet weak var detailLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var icon: UIImageView!
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
