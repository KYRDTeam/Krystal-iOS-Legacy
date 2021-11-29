//
//  OverviewTotalInfoCell.swift
//  KyberNetwork
//
//  Created by Com1 on 03/11/2021.
//

import UIKit

class OverviewTotalInfoCell: UICollectionViewCell {

  static let cellID: String = "OverviewTotalInfoCell"
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var backgroundContainView: UIView!
  @IBOutlet weak var hideBalanceButton: UIButton!
  @IBOutlet weak var totalValueLabel: UILabel!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var totalNetWorthLabel: UILabel!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var receiveButton: UIButton!

  var walletListButtonTapped: (() -> Void)?
  var walletOptionButtonTapped: (() -> Void)?
  var hideBalanceButtonTapped: (() -> Void)?
  var transferButtonTapped: (() -> Void)?
  var receiveButtonTapped: (() -> Void)?

  @IBAction func walletListButtonTapped(_ sender: UIButton) {
    if let walletListButtonTapped = walletListButtonTapped {
      walletListButtonTapped()
    }
  }

  @IBAction func hideBalanceButtonTapped(_ sender: Any) {
    if let hideBalanceButtonTapped = hideBalanceButtonTapped {
      hideBalanceButtonTapped()
    }
  }

  @IBAction func walletOptionButtonTapped(_ sender: Any) {
    if let walletOptionButtonTapped = walletOptionButtonTapped {
      walletOptionButtonTapped()
    }
  }

  @IBAction func transferButtonTapped(_ sender: Any) {
    if let transferButtonTapped = transferButtonTapped {
      transferButtonTapped()
    }
  }

  @IBAction func receiveButtonTapped(_ sender: Any) {
    if let receiveButtonTapped = receiveButtonTapped {
      receiveButtonTapped()
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundContainView.rounded(radius: 16.0)
  }

  private func updateUIForActionButtons(shouldShowAction: Bool) {
    self.transferButton.isHidden = !shouldShowAction
    self.receiveButton.isHidden = !shouldShowAction
    self.totalNetWorthLabel.isHidden = shouldShowAction
  }

  func updateCell(walletName: String, totalValue: String, hideBalanceStatus: Bool, shouldShowAction: Bool) {
    self.walletNameLabel.text = walletName
    self.totalValueLabel.text = totalValue
    self.updateUIForActionButtons(shouldShowAction: shouldShowAction)
    let eyeImage = hideBalanceStatus ? UIImage(named: "hide_eye_icon") : UIImage(named: "show_eye_icon")
    self.hideBalanceButton.setImage(eyeImage, for: .normal)
  }

}
