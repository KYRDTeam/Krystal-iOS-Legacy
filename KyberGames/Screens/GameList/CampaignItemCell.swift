//
//  CampaignItemCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class CampaignItemCell: UICollectionViewCell {
  @IBOutlet weak var imageView: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  func configure(campaign: Campaign) {
    imageView.loadImage(urlString: campaign.image)
  }
  
}
