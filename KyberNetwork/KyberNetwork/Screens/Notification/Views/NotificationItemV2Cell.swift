//
//  NotificationItemV2Cell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import UIKit

class NotificationItemV2Cell: UITableViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var unreadIndicatorView: UIView!
  
  func configure(viewModel: NotificationItemViewModel) {
    iconImageView.loadImage(viewModel.icon)
    titleLabel.text = viewModel.title
    timeLabel.text = viewModel.timeString
    contentLabel.text = viewModel.content
    unreadIndicatorView.isHidden = viewModel.isRead
  }
  
}
