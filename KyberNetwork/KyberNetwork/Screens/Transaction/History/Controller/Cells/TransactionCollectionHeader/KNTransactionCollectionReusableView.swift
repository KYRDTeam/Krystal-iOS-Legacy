// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNTransactionCollectionReusableView: UICollectionReusableView {

  static let viewID: String = "kTransactionCollectionReusableView"
  static let kOrderViewID: String = "kOrderCollectionReusableViewID"

  @IBOutlet weak var dateLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateView(with data: String) {
    self.dateLabel.text = data
  }
}
