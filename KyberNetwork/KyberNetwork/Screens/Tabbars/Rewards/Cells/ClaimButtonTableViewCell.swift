//
//  ClaimButtonTableViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2021.
//

import UIKit

class ClaimButtonTableViewCell: UITableViewCell {
  static let kCellID: String = "ClaimButtonTableViewCell"
  @IBOutlet weak var bgView: UIView!
  @IBOutlet weak var claimButton: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
   
  }
  
  override func layoutSubviews() {
    bgView.roundWithCustomCorner(corners: [.bottomRight, .bottomLeft], radius: 16)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
    
}
