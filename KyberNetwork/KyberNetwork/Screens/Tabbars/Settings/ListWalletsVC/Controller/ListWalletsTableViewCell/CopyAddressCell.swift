//
//  CopyAddressCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 14/04/2022.
//

import UIKit
import KrystalWallets

struct CopyAddressCellModel {
  let type: ChainType
  let address: KAddress
}

protocol CopyAddressCellDelegate: class {
  func copyAddressCellDidSelectAddress(cell: CopyAddressCell, address: String)
}

class CopyAddressCell: UITableViewCell {
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  
  weak var delegate: CopyAddressCellDelegate?

  @IBAction func copyButtonTapped(_ sender: UIButton) {
    self.delegate?.copyAddressCellDidSelectAddress(cell: self, address: self.addressLabel.text ?? "")
  }

  func updateCell(model: CopyAddressCellModel) {
    self.iconImageView.image = model.type.chainIcon()
    self.nameLabel.text = model.type.chainName()
    self.addressLabel.text = model.address.addressString
  }
}
