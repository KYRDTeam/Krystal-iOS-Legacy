//
//  FiatCryptoHistoryCell.swift
//  KyberNetwork
//
//  Created by Com1 on 13/03/2022.
//

import UIKit

class FiatCryptoHistoryCell: UICollectionViewCell {

  static let cellID: String = "kFiatCryptoHistoryCellID"
  static let height: CGFloat = 84.0

  @IBOutlet weak var cryptIcon: UIImageView!
  @IBOutlet weak var fiatIcon: UIImageView!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  
  
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

}
