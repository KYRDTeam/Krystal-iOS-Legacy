//
//  TxApplicationInfoCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 12/07/2022.
//

import UIKit

class TxApplicationInfoCell: UITableViewCell {

  @IBOutlet weak var walletAddressLabel: UILabel!
  @IBOutlet weak var applicationAddressLabel: UILabel!
  @IBOutlet weak var openWalletIcon: UIImageView!
  @IBOutlet weak var openApplicationIcon: UIImageView!
  
  var onOpenWallet: (() -> ())?
  var onOpenApplication: (() -> ())?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    let openWalletTap = UITapGestureRecognizer(target: self, action: #selector(onOpenWalletTapped))
    openWalletIcon.isUserInteractionEnabled = true
    openWalletIcon.addGestureRecognizer(openWalletTap)
    
    
    let openApplicationTap = UITapGestureRecognizer(target: self, action: #selector(onOpenApplicationTapped))
    openApplicationIcon.isUserInteractionEnabled = true
    openApplicationIcon.addGestureRecognizer(openApplicationTap)
  }
  
  @objc func onOpenWalletTapped() {
    self.onOpenWallet?()
  }
  
  @objc func onOpenApplicationTapped() {
    self.onOpenApplication?()
  }
  
  func configure(walletAddress: String, applicationAddress: String) {
    self.walletAddressLabel.text = walletAddress
    self.applicationAddressLabel.text = applicationAddress
  }
  
}
