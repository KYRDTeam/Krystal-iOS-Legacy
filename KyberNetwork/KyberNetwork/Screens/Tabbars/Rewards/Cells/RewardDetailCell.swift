//
//  RewardDetailCell.swift
//  KyberNetwork
//
//  Created by Com1 on 13/10/2021.
//

import UIKit

class RewardDetailCell: UITableViewCell {
  static let kCellID: String = "RewardDetailCell"
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var dateTimeLabel: UILabel!
  @IBOutlet weak var sourceLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var statusBackgroundView: UIView!
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
    
  func updateCell(model: KNRewardModel) {
    valueLabel.text = "+ " + StringFormatter.amountString(value: model.amount) + " " + model.rewardSymbol
    let date = Date(timeIntervalSince1970: TimeInterval(model.timestamp))
    dateTimeLabel.text = DateFormatterUtil.shared.rewardDateTimeFormatter.string(from: date)
    sourceLabel.text = model.source
    statusLabel.text = model.status.capitalized
    statusBackgroundView.backgroundColor = model.status.lowercased() == "claimed" ? UIColor(named: "investButtonBgColor")! : UIColor(named: "actionsheetSelectedColor")!
  }
}
