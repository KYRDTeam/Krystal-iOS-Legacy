//
//  BridgeSwapButtonCell.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class BridgeSwapButtonCell: UITableViewCell {
  @IBOutlet weak var swapButton: UIButton!
  var swapBlock: (() -> Void)?
  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
    
  @IBAction func swapButtonTapped(_ sender: Any) {
    if let swapBlock = self.swapBlock {
      swapBlock()
    }
  }
}
