//
//  PortfolioAssetCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 11/07/2022.
//

import UIKit

class PortfolioAssetCell: UITableViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var verifiedImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  
  func configure(viewModel: PortfolioAssetCellViewModel) {
    iconImageView.setSymbolImage(symbol: viewModel.symbol)
    nameLabel.text = viewModel.displaySymbol
  }
  
}
