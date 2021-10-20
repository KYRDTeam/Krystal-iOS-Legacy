//
//  ClaimButtonTableViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2021.
//

import UIKit

class ClaimButtonTableViewCell: UITableViewCell {
  static let kCellID: String = "ClaimButtonTableViewCell"
  @IBOutlet weak var bgView: UIView!
  var onClaimButtonTapped: (() -> Void)?
  override func awakeFromNib() {
    super.awakeFromNib()
  }

  @IBAction func onClaimButtonTapped(_ sender: Any) {
    guard let onClaimButtonTapped = onClaimButtonTapped else { return }
    onClaimButtonTapped()
  }
  override func layoutSubviews() {
    bgView.roundWithCustomCorner(corners: [.bottomRight, .bottomLeft], radius: 16)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
  
}
