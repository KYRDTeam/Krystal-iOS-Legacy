//
//  OverviewMainViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/10/21.
//

import UIKit
import BigInt
import SwipeCellKit

class OverviewMainViewCell: UITableViewCell {
  static let kCellID: String = "OverviewMainViewCell"
  static let kCellHeight: CGFloat = 60
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var tokenValueLabel: UILabel!
  @IBOutlet weak var change24Button: UIButton!
  @IBOutlet weak var tagImageView: UIImageView!
  var action: (() -> ())?
  var viewModel: OverviewMainCellViewModel?
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.change24Button.rounded(radius: 6)
  }
  
  func updateCell(_ viewModel: OverviewMainCellViewModel) {
    self.viewModel = viewModel
    self.iconImageView.setImage(urlString: viewModel.logo, symbol: viewModel.displayTitle)
    self.tokenLabel.text = viewModel.displayTitle
    self.tokenBalanceLabel.text = viewModel.displaySubTitleDetail
    self.tokenValueLabel.text = viewModel.displayAccessoryTitle
    self.tokenValueLabel.textColor = viewModel.displayAccessoryTextColor
    self.change24Button.isHidden = viewModel.displayDetailBox.isEmpty
    self.change24Button.setTitle(viewModel.displayDetailBox, for: .normal)
    self.change24Button.backgroundColor = viewModel.displayAccessoryColor
    if viewModel.displayDetailBox == "---" {
      self.change24Button.setTitleColor(UIColor(named: "textWhiteColor"), for: .normal)
      self.change24Button.contentHorizontalAlignment = .right
    } else {
      self.change24Button.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
      self.change24Button.contentHorizontalAlignment = .center
    }
    if let image = viewModel.tagImage {
      self.tagImageView.image = image
      self.tagImageView.isHidden = false
    } else {
      self.tagImageView.isHidden = true
    }
  }
  
  @IBAction func tapOnRightSide(_ sender: Any) {
    if let unwrap = self.viewModel, unwrap.displayDetailBox.isEmpty {
      (self.action ?? {})()
    }
  }
  
  @IBAction func tapAccessoryBox(_ sender: UIButton) {
    if let unwrap = self.viewModel, !unwrap.displayDetailBox.isEmpty {
      (self.action ?? {})()
    }
  }
}
