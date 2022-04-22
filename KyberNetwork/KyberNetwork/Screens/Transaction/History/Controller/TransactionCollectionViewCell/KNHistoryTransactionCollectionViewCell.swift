// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import BigInt

class KNHistoryTransactionCollectionViewCell: SwipeCollectionViewCell {

  static let cellID: String = "kHistoryTransactionCellID"
  static let height: CGFloat = 68.0

  @IBOutlet weak var transactionAmountLabel: UILabel!
  @IBOutlet weak var transactionDetailsLabel: UILabel!
  @IBOutlet weak var transactionTypeLabel: UILabel!
  @IBOutlet weak var transactionStatus: UIButton!
  @IBOutlet weak var historyTypeImage: UIImageView!
  @IBOutlet weak var fromIconImage: UIImageView!
  @IBOutlet weak var toIconImage: UIImageView!
  @IBOutlet weak var dateTimeLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // reset data
    self.transactionAmountLabel.text = ""
    self.transactionDetailsLabel.text = ""
    self.transactionTypeLabel.text = ""
    self.transactionStatus.rounded(radius: 10.0)
  }

  func updateCell(with model: TransactionHistoryItemViewModelProtocol) {
    let hasFromToIcon = !model.fromIconSymbol.isEmpty && !model.toIconSymbol.isEmpty
    self.transactionAmountLabel.text = model.displayedAmountString
    self.transactionDetailsLabel.text = model.transactionDetailsString
    self.transactionTypeLabel.text = model.transactionTypeString.uppercased()
    self.transactionStatus.setTitle(model.isError ? "Failed" : "", for: .normal)
    self.transactionStatus.isHidden = !model.isError
    self.hideSwapIcon(!hasFromToIcon)
    self.historyTypeImage.isHidden = hasFromToIcon
    if hasFromToIcon {
      self.fromIconImage.setSymbolImage(symbol: model.fromIconSymbol, size: self.toIconImage.frame.size)
      self.toIconImage.setSymbolImage(symbol: model.toIconSymbol, size: self.toIconImage.frame.size)
    } else {
      self.historyTypeImage.image = model.transactionTypeImage
    }
    self.dateTimeLabel.text = model.displayTime
    self.layoutIfNeeded()
  }

  fileprivate func hideSwapIcon(_ hidden: Bool) {
    self.fromIconImage.isHidden = hidden
    self.toIconImage.isHidden = hidden
  }
}
