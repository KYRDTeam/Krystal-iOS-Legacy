//
//  CustomTokenTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/21/21.
//

import UIKit
import SwipeCellKit

struct CustomTokenCellViewModel {
  let token: Token
  let balance: String
}

/// Value in USD to validate if current token should display blue tick or not
let hightVolAmount = 100000.0

class CustomTokenTableViewCell: SwipeTableViewCell {
    static let kCellID: String = "CustomTokenTableViewCell"
    static let kCellHeight: CGFloat = 60
    @IBOutlet weak var imageIcon: UIImageView!
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var statusSwitch: UISwitch!
    @IBOutlet weak var tickIcon: UIImageView!
    var viewModel: CustomTokenCellViewModel?
    var onUpdateActiveStatus: (() -> Void)?

    func updateCell(_ viewModel: CustomTokenCellViewModel) {
      self.viewModel = viewModel
      self.imageIcon.setSymbolImage(symbol: viewModel.token.symbol, size: CGSize(width: 17, height: 17))
      self.tokenNameLabel.text = viewModel.token.symbol.uppercased()
      self.balanceLabel.text = viewModel.balance
      self.statusSwitch.isOn = KNSupportedTokenStorage.shared.getTokenActiveStatus(viewModel.token)
      self.tickIcon.isHidden = viewModel.token.getVol(.usd) < hightVolAmount || KNSupportedTokenStorage.shared.getFullCustomToken().contains(viewModel.token)
    }

    @IBAction func switchChangedValue(_ sender: UISwitch) {
      if let notNil = self.viewModel, let onUpdateActiveStatus = onUpdateActiveStatus {
        KNSupportedTokenStorage.shared.setTokenActiveStatus(token: notNil.token, status: sender.isOn)
        onUpdateActiveStatus()
      }
    }
}
