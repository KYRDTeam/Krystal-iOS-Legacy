//
//  MarketingPartnerCollectionViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import UIKit

class MarketingPartnerCollectionViewCell: UICollectionViewCell {
  
  static let kMarketingPartnerCellHeight: CGFloat = 80
  
  @IBOutlet weak var bannerImageView: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    bannerImageView.clipsToBounds = true
  }
  
  func configure(asset: Asset) {
    let url = URL(string: asset.imageURL)
    bannerImageView.kf.setImage(with: url)
  }
}
