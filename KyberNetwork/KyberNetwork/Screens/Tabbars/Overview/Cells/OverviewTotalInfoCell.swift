//
//  OverviewTotalInfoCell.swift
//  KyberNetwork
//
//  Created by Com1 on 03/11/2021.
//

import UIKit

class OverviewTotalInfoCell: UICollectionViewCell {

  static let cellID: String = "OverviewTotalInfoCell"
  @IBOutlet weak var backgroundContainView: UIView!
  @IBOutlet weak var hideBalanceButton: UIButton!
  @IBOutlet weak var totalValueLabel: UILabel!
  @IBOutlet weak var totalNetWorthLabel: UILabel!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var receiveButton: UIButton!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainButton: UIButton!
  @IBOutlet weak var chainView: UIView!
  
  var chainButtonTapped: (() -> Void)?
  var walletOptionButtonTapped: (() -> Void)?
  var hideBalanceButtonTapped: (() -> Void)?
  var transferButtonTapped: (() -> Void)?
  var receiveButtonTapped: (() -> Void)?
  
  var isAllChainOverralCell: Bool = false

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
    self.addGestures()
    self.backgroundContainView.rounded(radius: 16.0)
  }
  
  func addGestures() {
    chainView.isUserInteractionEnabled = true
    let gesture = UITapGestureRecognizer(target: self, action: #selector(onTapChainButton))
    gesture.cancelsTouchesInView = false
    chainView.addGestureRecognizer(gesture)
  }
  
  @objc func onTapChainButton() {
    if !isAllChainOverralCell {
      chainButtonTapped?()
    }
  }

  private func updateUIForActionButtons(shouldShowAction: Bool) {
    self.transferButton.isHidden = !shouldShowAction
    self.receiveButton.isHidden = !shouldShowAction
    self.totalNetWorthLabel.isHidden = shouldShowAction
  }

  func updateCell(chain: ChainType, totalValue: String, hideBalanceStatus: Bool, shouldShowAction: Bool, isAllChainOverralCell: Bool) {
    self.isAllChainOverralCell = isAllChainOverralCell
    self.chainIcon.image = chain.squareIcon()
    self.chainButton.setTitle(chain.chainName(), for: .normal)
    self.totalValueLabel.text = totalValue
    self.updateUIForActionButtons(shouldShowAction: shouldShowAction)
    let eyeImage = hideBalanceStatus ? UIImage(named: "hide_eye_icon") : UIImage(named: "show_eye_icon")
    self.hideBalanceButton.setImage(eyeImage, for: .normal)
    self.chainButton.setImage(isAllChainOverralCell ? nil : Images.arrowDropDownWhite, for: .normal)
  }

}
