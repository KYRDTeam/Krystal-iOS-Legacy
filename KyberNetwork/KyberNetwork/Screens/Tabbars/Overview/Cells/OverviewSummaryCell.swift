//
//  OvereviewSummaryCell.swift
//  KyberNetwork
//
//  Created by Com1 on 04/11/2021.
//

import UIKit

class OverviewSummaryCell: UITableViewCell {
  static let kCellID: String = "OvereviewSummaryCell"
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainValueLabel: UILabel!
  @IBOutlet weak var chainNameLabel: UILabel!
  @IBOutlet weak var percentLabel: UILabel!
  @IBOutlet weak var backgroundContainView: UIView!
  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundContainView.rounded(radius: 16)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }

}
