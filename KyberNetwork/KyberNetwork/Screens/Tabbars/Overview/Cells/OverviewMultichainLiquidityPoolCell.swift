//
//  OverviewMultichainLiquidityPoolCell.swift
//  KyberNetwork
//
//  Created by Com1 on 27/07/2022.
//

import UIKit

class OverviewMultichainLiquidityPoolCell: UITableViewCell {
  static let kCellID: String = "OverviewLiquidityPoolCell"
  static let kCellHeight: CGFloat = 85
  @IBOutlet weak var cellBackgroundView: UIView!
  @IBOutlet weak var firstTokenIcon: UIImageView!
  @IBOutlet weak var secondTokenIcon: UIImageView!
  @IBOutlet weak var firstTokenValueLabel: UILabel!
  @IBOutlet weak var secondTokenValueLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var chainIcon: UIImageView!
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
  
  func updateCell(_ viewModel: OverviewLiquidityPoolViewModel) {
    if viewModel.firstTokenLogo().isEmpty {
      self.firstTokenIcon.setSymbolImage(symbol: viewModel.firstTokenSymbol())
    } else {
      self.firstTokenIcon.setImage(with: viewModel.firstTokenLogo(), placeholder: UIImage(named: "default_token")!)
    }
  
    if viewModel.secondTokenLogo().isEmpty {
      self.secondTokenIcon.setSymbolImage(symbol: viewModel.secondTokenSymbol())
    } else {
      self.secondTokenIcon.setImage(with: viewModel.secondTokenLogo(), placeholder: UIImage(named: "default_token")!)
    }
    
    self.firstTokenValueLabel.text = viewModel.firstTokenValue()
    self.secondTokenValueLabel.text = viewModel.secondTokenValue()
    self.balanceLabel.text = viewModel.balanceValue()
    if let url = URL(string: viewModel.chainLogo) {
      self.chainIcon.setImage(with: url, placeholder: nil)
    } else {
      self.chainIcon.image = ChainType.make(chainID: viewModel.chainId)?.chainIcon()
    }
  }
    
}
