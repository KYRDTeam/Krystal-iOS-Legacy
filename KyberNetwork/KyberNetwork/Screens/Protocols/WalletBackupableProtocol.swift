//
//  WalletBackupableProtocol.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 05/10/2022.
//

import Foundation
import UIKit
import KrystalWallets

protocol WalletExportableProtocol {
  var navigation: UINavigationController { get set }
  
  func export(wallet: KWallet, addressType: KAddressType)
  func delete()
}
