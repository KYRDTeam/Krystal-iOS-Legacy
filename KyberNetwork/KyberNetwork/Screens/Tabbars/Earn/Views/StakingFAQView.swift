//
//  StakingFAQView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/11/2022.
//

import Foundation
import UIKit

@IBDesignable
class StakingFAQView: BaseXibView {
  
  @IBOutlet weak var mainTitleLabel: UILabel!
  @IBOutlet weak var mainExpandButton: UIButton!
  @IBOutlet weak var contentTableView: UITableView!
  
  override func commonInit() {
    super.commonInit()
    
    registerCell()
  }
  
  private func registerCell() {
    
  }
  
  @IBAction func expandButtonTapped(_ sender: UIButton) {
  }
  
  override var intrinsicContentSize: CGSize {
    let superSize = super.intrinsicContentSize
    return CGSize(width: superSize.width, height: 100)
  }
}
