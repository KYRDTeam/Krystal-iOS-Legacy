//
//  RewardTableViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2021.
//

import UIKit

class RewardTableViewCell: UITableViewCell {
  static let kCellID: String = "RewardTableViewCell"
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var bgView: UIView!
  @IBOutlet weak var tokenImageView: UIImageView!
  
  var shouldRoundTopBGView = false
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if shouldRoundTopBGView {
      DispatchQueue.main.async {
        self.bgView.roundWithCustomCorner(corners: [.topRight, .topLeft], radius: 16)
      }
    }
  }
  


  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
  
  func updateCell(model: KNRewardModel) {
    tokenBalanceLabel.text = StringFormatter.amountString(value: model.amount) + " " + model.rewardSymbol
    if model.rewardImage.isEmpty {
      tokenImageView.setSymbolImage(symbol: model.rewardSymbol)
    } else {
      tokenImageView.setImage(with: model.rewardImage, placeholder: UIImage(named: "default_token")!)
    }
    valueLabel.text = "$" + StringFormatter.currencyString(value: model.value, symbol: model.symbol)
  }
}
