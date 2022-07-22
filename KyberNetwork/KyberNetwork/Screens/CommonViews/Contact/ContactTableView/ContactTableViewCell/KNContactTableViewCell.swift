// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import KrystalWallets

struct KNContactTableViewCellModel {
  let contact: KNContact
  let index: Int

  init(
    contact: KNContact,
    index: Int
    ) {
    self.contact = contact
    self.index = index
  }

  var addressImage: UIImage? {
    if self.contact.address.isValidSolanaAddress() {
      guard let data = SolanaUtil.convertBase58Data(addressString: self.contact.address) else { return nil }
      return UIImage.generateImage(with: 32, hash: data)
    } else {
      guard KNGeneralProvider.shared.isAddressValid(address: contact.address) else { return nil }
      guard let data = Data(hexString: contact.address) else { return nil }
      return UIImage.generateImage(with: 32, hash: data)
    }
    
  }

  var displayedName: String { return self.contact.name }

  var nameAndAddressAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()

    return attributedString
  }

  var displayedAddress: String {
    let address = self.contact.address
    if address.isValidSolanaAddress() {
      return "\(address.prefix(20))...\(address.suffix(6))"
    }
    return "\(address.lowercased().prefix(20))...\(address.lowercased().suffix(6))"
  }

  var backgroundColor: UIColor {
    return self.index % 2 == 0 ? UIColor.clear : UIColor.white
  }
}

struct KNWalletTableCellViewModel {
  let address: KAddress
  
  var addressImage: UIImage? {
    guard let data = Data(hexString: address.addressString) else {
      return nil
    }
    return UIImage.generateImage(with: 32, hash: data)
  }

  var displayedName: String { return self.address.name }
  var displayedAddress: String {
    let address = self.address.addressString
    return "\(address.prefix(20))...\(address.suffix(6))"
  }
}

class KNContactTableViewCell: SwipeTableViewCell {

  static let height: CGFloat = 60

  @IBOutlet weak var addressImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var contactAddressLabel: UILabel!
  
  @IBOutlet weak var checkIcon: UIImageView!
  @IBOutlet weak var addressImageLeftPaddingContraint: NSLayoutConstraint!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.contactNameLabel.text = ""
    self.contactAddressLabel.text = ""
    self.addressImageView.rounded(radius: self.addressImageView.frame.height / 2.0)
  }

  func update(with viewModel: KNContactTableViewCellModel) {
    self.addressImageView.image = viewModel.addressImage
    self.contactNameLabel.text = viewModel.displayedName
    self.contactNameLabel.addLetterSpacing()
    self.contactAddressLabel.text = viewModel.displayedAddress
    self.contactAddressLabel.addLetterSpacing()
    self.addressImageLeftPaddingContraint.constant = 24
    self.checkIcon.isHidden = true
    self.layoutIfNeeded()
  }

  func update(with viewModel: KNWalletTableCellViewModel, selected: KAddress?) {
    self.addressImageView.image = viewModel.addressImage
    self.contactNameLabel.text = viewModel.displayedName
    self.contactNameLabel.addLetterSpacing()
    self.contactAddressLabel.text = viewModel.displayedAddress
    self.contactAddressLabel.addLetterSpacing()
    let isSelected = viewModel.address.addressString == selected?.addressString
    self.addressImageLeftPaddingContraint.constant = (isSelected ? 66.0 : 24.0)
    self.checkIcon.isHidden = !isSelected
    self.layoutIfNeeded()
  }
}
