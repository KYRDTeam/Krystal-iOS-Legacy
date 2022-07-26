//
//  OverviewAllChainTokenCell.swift
//  KyberNetwork
//
//  Created by Com1 on 19/07/2022.
//

import UIKit
import SwipeCellKit

class OverviewAllChainTokenCell: UITableViewCell {
  static let kCellHeight: CGFloat = 60
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var tokenValueLabel: UILabel!
//  @IBOutlet weak var change24Button: UIButton!
  @IBOutlet weak var tagImageView: UIImageView!
  var action: (() -> ())?
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }
  
  func updateCell(_ viewModel: OverviewMainCellViewModel) {
    if let url = URL(string: viewModel.chainLogo) {
      self.chainIcon.setImage(with: url, placeholder: nil)
    } else {
      self.chainIcon.image = ChainType.make(chainID: viewModel.chainId)?.chainIcon()
    }
    
    self.iconImageView.setImage(urlString: viewModel.logo, symbol: viewModel.displayTitle)
    self.tokenLabel.text = viewModel.displayTitle
    self.tokenBalanceLabel.text = viewModel.multiChainSubTitle
    self.tokenValueLabel.text = viewModel.multiChainAccessoryTitle
    self.tokenValueLabel.textColor = viewModel.multichainAccessoryTextColor
    if let image = viewModel.tagImage {
      self.tagImageView.image = image
      self.tagImageView.isHidden = false
    } else {
      self.tagImageView.isHidden = true
    }
  }
  
  @IBAction func tapOnRightSide(_ sender: Any) {
    (self.action ?? {})()
  }
}
