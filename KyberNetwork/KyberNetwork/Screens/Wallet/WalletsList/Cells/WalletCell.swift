//
//  WalletCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 19/08/2022.
//

import UIKit
import KrystalWallets
import AppState

protocol WalletCellModel {
  func displayAvatar() -> UIImage?
  func displayWalletName() -> String
  func diplayWalletAddress() -> String
  func isBackupedWallet() -> Bool
  func isCurrentWallet() -> Bool
}

struct RealWalletCellModel: WalletCellModel {
  func displayAvatar() -> UIImage? {
    guard let address = WalletManager.shared.getAllAddresses(walletID: wallet.id).first, let data = address.addressString.dataFromHex() else { return nil }
    return UIImage.generateImage(with: 32, hash: data)
  }
  
  func displayWalletName() -> String {
    return wallet.name
  }
  
  func diplayWalletAddress() -> String {
    let typeString = wallet.importType == .mnemonic ? "Multichain" : wallet.generateWalletDescrition()
    return typeString
  }
  
  func isBackupedWallet() -> Bool {
      return WalletExtraDataManager.shared.isWalletBackedUp(walletID: wallet.id)
  }
  
  func isCurrentWallet() -> Bool {
    return AppDelegate.session.address.walletID == wallet.id
  }
  
  let wallet: KWallet
}

struct WatchWalletCellModel: WalletCellModel {
  func displayAvatar() -> UIImage? {
    guard let data = address.addressString.dataFromHex() else { return nil }
    return UIImage.generateImage(with: 32, hash: data)
  }
  
  func displayWalletName() -> String {
    return address.name
  }
  
  func diplayWalletAddress() -> String {
    return address.generateAddressDescription()
  }
  
  func isBackupedWallet() -> Bool {
    return true
  }
  
  func isCurrentWallet() -> Bool {
    return AppDelegate.session.address.addressString == address.addressString
  }
  
  let address: KAddress
}

class WalletCell: UITableViewCell {
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletDescriptionLabel: UILabel!
  @IBOutlet weak var descriptionLabelBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var backupLabel: UILabel!
  @IBOutlet weak var backupView: UIView!
  @IBOutlet weak var checkIcon: UIImageView!
  var didSelectBackup: (() -> Void)?
  static let cellHeight: CGFloat = 60
  static let cellID: String = "WalletCell"
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateCell(_ cellModel: WalletCellModel) {
    iconImageView.image = cellModel.displayAvatar()
    walletNameLabel.text = cellModel.displayWalletName()
    walletDescriptionLabel.text = cellModel.diplayWalletAddress()
    if cellModel.isBackupedWallet() {
      descriptionLabelBottomConstraint.constant = 13
      backupLabel.isHidden = true
      backupView.isHidden = true
    } else {
      descriptionLabelBottomConstraint.constant = 33
      backupLabel.isHidden = false
      backupView.isHidden = false
    }
    checkIcon.isHidden = !cellModel.isCurrentWallet()
  }

  @IBAction func backupButtonTapped(_ sender: Any) {
    if let didSelectBackup = didSelectBackup {
      didSelectBackup()
    }
  }
}

extension KWallet {
  func generateWalletDescrition() -> String {
    if let address = WalletManager.shared.getAllAddresses(walletID: id).first {
      return address.generateAddressDescription()
    }

    return "---"
  }
}

extension KAddress {
  func generateAddressDescription() -> String {
    let chainType = self.addressString.has0xPrefix ? "Ethereum" : "Solana"
    
    return "\(self.addressString.shortTypeAddress)  •  \(chainType)"
  }
}
