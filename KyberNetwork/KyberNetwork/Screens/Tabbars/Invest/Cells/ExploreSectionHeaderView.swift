//
//  ExploreSectionHeaderView.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import UIKit

class ExploreSectionHeaderView: UICollectionReusableView {
  
  @IBOutlet weak var titleLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  func configure(title: String) {
    titleLabel.text = title
  }
  
}
