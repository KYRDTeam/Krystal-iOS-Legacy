//
//  SwapV2PlatformCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import UIKit

class SwapV2PlatformCell: UITableViewCell {
  @IBOutlet weak var iconLabel: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var feeLabel: UILabel!
  @IBOutlet weak var amountUsdLabel: UILabel!
  
  func configure(viewModel: SwapPlatformItemViewModel) {
    iconLabel.loadImage(viewModel.icon)
    nameLabel.text = viewModel.name
    amountLabel.text = viewModel.amountString
    feeLabel.text = viewModel.feeString
    amountUsdLabel.text = viewModel.amountUsdString
  }
}
