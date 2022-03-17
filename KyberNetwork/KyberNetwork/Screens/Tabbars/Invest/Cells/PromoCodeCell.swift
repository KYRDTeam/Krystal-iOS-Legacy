//
//  PromoCodeCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/03/2022.
//

import UIKit
import Kingfisher

protocol PromoCodeCellDelegate: class {
  func promoCodeCell(_ cell: PromoCodeCell, claim code: String)
}

class PromoCodeCellModel {
  let item: PromoCode
  
  init(item: PromoCode) {
    self.item = item
  }
  
  var displayTitle: String {
    return self.item.campaign.title
  }
  
  var displayStatus: String {
    switch self.item.getStatus() {
    case .pending:
      let date = Date(timeIntervalSince1970: Double(self.item.campaign.expired))
      let stringDate = DateFormatterUtil.shared.notificationDisplayDateFormatter.string(from: date)
      return "Valid until \(stringDate)"
    case .claimed:
      return "Used"
    case .expired:
      return "Expired"
    }
  }
  
  var hiddenUseButton: Bool {
    return self.item.getStatus() != .pending
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
  weak var delegate: PromoCodeCellDelegate?
  
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
    if let url = URL(string: cm.item.campaign.logoURL) {
      self.iconImageView.kf.setImage(with: url, placeholder: UIImage(named: "promo_code_default_icon"), options: [.cacheMemoryOnly])
    } else {
      self.iconImageView.image = UIImage(named: "promo_code_default_icon")
    }
    self.cellModel = cm
  }

  @IBAction func useButtonTapped(_ sender: UIButton) {
    guard let cm = self.cellModel else { return }
    self.delegate?.promoCodeCell(self, claim: cm.item.code)
  }
}
