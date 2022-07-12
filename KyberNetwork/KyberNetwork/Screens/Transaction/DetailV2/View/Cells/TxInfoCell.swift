//
//  BridgeTxFeeCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/05/2022.
//

import UIKit
import BigInt

class TxInfoCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var helpIcon: UIImageView!
  @IBOutlet weak var actionImageView: UIImageView!
  
  var onAction: (() -> ())?
  var helpHandler: (() -> ())?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    setupViews()
  }
  
  func setupViews() {
    actionImageView.isUserInteractionEnabled = true
    let actionTap = UITapGestureRecognizer(target: self, action: #selector(onActionTap))
    actionImageView.addGestureRecognizer(actionTap)
    
    let helpTap = UITapGestureRecognizer(target: self, action: #selector(onTapHelp))
    helpIcon.isUserInteractionEnabled = true
    helpIcon.addGestureRecognizer(helpTap)
  }
  
  @objc func onTapHelp() {
    self.helpHandler?()
  }
  
  @objc func onActionTap() {
    self.onAction?()
  }
  
  func configure(title: String, value: String, actionIcon: UIImage? = nil, showHelpIcon: Bool = false) {
    titleLabel.text = title
    valueLabel.text = value
    helpIcon.isHidden = !showHelpIcon
    actionImageView.image = actionIcon
    actionImageView.isHidden = actionIcon == nil
  }
  
}
