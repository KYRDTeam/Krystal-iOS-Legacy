//
//  CopyAddressCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 14/04/2022.
//

import UIKit

struct CopyAddressCellModel {
  let type: ChainType
  let data: WalletData
}

protocol CopyAddressCellDelegate: class {
  func copyAddressCellDidSelectAddress(cell: CopyAddressCell, address: String)
}

class CopyAddressCell: UITableViewCell {
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  
  weak var delegate: CopyAddressCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  @IBAction func copyButtonTapped(_ sender: UIButton) {
    self.delegate?.copyAddressCellDidSelectAddress(cell: self, address: self.addressLabel.text ?? "")
  }

  func updateCell(model: CopyAddressCellModel) {
    self.iconImageView.image = model.type.chainIcon()
    self.nameLabel.text = model.type.chainName()
    self.addressLabel.text = model.data.address
  }
}
