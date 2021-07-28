//
//  WalletListSectionTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/13/21.
//

import UIKit

struct WalletListSectionTableViewCellViewModel {
  let sectionTile: String
  let isFirstSection: Bool
}

protocol WalletListSectionTableViewCellDelegate: class {
  func walletListSectionTableViewCellDidSelectAction(_ cell: WalletListSectionTableViewCell)
}

class WalletListSectionTableViewCell: UITableViewCell {
  @IBOutlet weak var sectionTitleLabel: UILabel!
  @IBOutlet weak var lineView: UIView!
  @IBOutlet weak var addButton: UIButton!
  var viewModel: WalletListSectionTableViewCellViewModel?
  weak var delegate: WalletListSectionTableViewCellDelegate?

  func updateCellWith(viewModel: WalletListSectionTableViewCellViewModel) {
    self.viewModel = viewModel
    self.sectionTitleLabel.text = viewModel.sectionTile
    self.lineView.isHidden = viewModel.isFirstSection
    self.addButton.isHidden = !viewModel.isFirstSection
  }

  @IBAction func addButtonTapped(_ sender: UIButton) {
    self.delegate?.walletListSectionTableViewCellDidSelectAction(self)
  }
}
