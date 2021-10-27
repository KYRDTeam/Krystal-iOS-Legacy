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
  @IBOutlet weak var claimButton: UIButton!
  var onClaimButtonTapped: (() -> Void)?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.claimButton.titleLabel?.font = UIFont.Kyber.bold(with: 15)
    self.claimButton.setTitleColor(UIColor(named: "buttonTextColor"), for: .normal)
    self.claimButton.setTitle("Claim All", for: .normal)
  }

  func setClaimButtonState(isEnabled: Bool) {
    self.claimButton.isEnabled = isEnabled
    self.claimButton.backgroundColor = isEnabled ? UIColor(named: "buttonBackgroundColor")! : UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
  }

  @IBAction func onClaimButtonTapped(_ sender: Any) {
    guard let onClaimButtonTapped = onClaimButtonTapped else { return }
    onClaimButtonTapped()
  }
  override func layoutSubviews() {
    DispatchQueue.main.async {
      self.bgView.roundWithCustomCorner(corners: [.bottomRight, .bottomLeft], radius: 16)
    }
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
  
}
