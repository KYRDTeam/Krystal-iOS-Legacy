//
//  BrowserCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 31/12/2021.
//

import UIKit
import SwipeCellKit
import Utilities

struct BrowserCellViewModel {
  let item: BrowserItem
  
  var title: String {
    return self.item.title
  }
  
  var subTitle: String {
    return self.item.url
  }
  
  var imageURL: String {
    return self.item.image ?? ""
  }
}

class BrowserCell: SwipeTableViewCell {
  
  static let cellHeight: CGFloat = 80
  static let cellID: String = "BrowserCell"
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    
  }

  func setUpUI(viewModel: BrowserCellViewModel) {
    self.titleLabel.text = viewModel.title
    self.subTitleLabel.text = viewModel.subTitle
    self.iconImageView.loadImage(viewModel.imageURL)
  }
}
