// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import KrystalWallets

struct KNListWalletsTableViewCellModel {
  let wallet: KWallet
  let address: String
}

struct KNListWalletsWatchAddressCellModel {
  let address: KAddress
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

  func updateCell(cellModel: KNListWalletsTableViewCellModel) {
    self.walletNameLabel.text = cellModel.wallet.name
    self.walletAddressLabel.text = cellModel.address
  }
  
  func configure(watchAddressCellModel cellModel: KNListWalletsWatchAddressCellModel) {
    self.walletNameLabel.text = cellModel.address.name
    self.walletAddressLabel.text = cellModel.address.addressString
  }
}
