// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustCore
import SwipeCellKit

struct KNListWalletsTableViewCellModel {
  let wallet: WalletData
  let isMultipleWallet: Bool
}

class KNListWalletsTableViewCell: SwipeTableViewCell {

  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletAddressLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.walletNameLabel.text = "Untitled"
    self.walletAddressLabel.text = ""
    self.backgroundColor = .clear
  }

  func updateCell(with wallet: KNWalletObject, id: Int) {
    self.walletNameLabel.text = wallet.name
    self.walletAddressLabel.text = wallet.address.lowercased()
    self.layoutIfNeeded()
  }
  
  func updateCell(cellModel: KNListWalletsTableViewCellModel) {
    self.walletNameLabel.text = cellModel.wallet.name
    self.walletAddressLabel.text = cellModel.isMultipleWallet ? "" : cellModel.wallet.address
  }
}
