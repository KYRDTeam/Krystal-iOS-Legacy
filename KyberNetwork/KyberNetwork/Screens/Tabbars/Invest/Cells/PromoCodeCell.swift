//
//  PromoCodeCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/03/2022.
//

import UIKit

class PromoCodeCellModel {
  let item: PromoCodeItem
  
  init(item: PromoCodeItem) {
    self.item = item
  }
  
  var displayTitle: String {
    return self.item.title
  }
  
  var displayStatus: String {
    switch self.item.type {
    case .pending:
      let date = Date(timeIntervalSince1970: self.item.expired)
      let stringDate = DateFormatterUtil.shared.notificationDisplayDateFormatter.string(from: date)
      return "Valid until \(stringDate)"
    case .claimed:
      return "Used"
    case .expired:
      return "Expired"
    }
  }
  
  var hiddenUseButton: Bool {
    return self.item.type != .pending
  }
}

class PromoCodeCell: UITableViewCell {
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var separatorView: UIView!
  @IBOutlet weak var useButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var statusLabel: UILabel!
  
  var cellModel: PromoCodeCellModel?
  
  static let cellID: String = "PromoCodeCell"
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.containerView.rounded(radius: 16)
    self.separatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
    self.useButton.rounded(radius: 16)
  }
  
  func updateCellModel(_ cm: PromoCodeCellModel) {
    self.titleLabel.text = cm.displayTitle
    self.statusLabel.text = cm.displayStatus
    self.useButton.isHidden = cm.hiddenUseButton
    self.cellModel = cm
  }
}
