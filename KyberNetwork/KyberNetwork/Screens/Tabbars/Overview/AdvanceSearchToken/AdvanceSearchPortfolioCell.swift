//
//  AdvanceSearchPortfolioCell.swift
//  KyberNetwork
//
//  Created by Com1 on 15/06/2022.
//

import UIKit

class AdvanceSearchPortfolioCell: UITableViewCell {
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var iconImgView: UIImageView!

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  func updateUI(portfolio: Portfolio?) {
    guard let portfolio = portfolio else {
      return
    }
    addressLabel.text = portfolio.id
    nameLabel.text = portfolio.ens
    
  }
    
}
