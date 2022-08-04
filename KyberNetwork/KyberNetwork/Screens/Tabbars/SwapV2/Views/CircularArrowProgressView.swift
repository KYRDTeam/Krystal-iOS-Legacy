//
//  CircularArrowProgressView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 03/08/2022.
//

import UIKit

class CircularArrowProgressView: BaseXibView {
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var backgroundProgressView: CircularProgressView!
  @IBOutlet weak var excludeImageView: UIImageView!
  
  override func commonInit() {
    super.commonInit()
    
    excludeImageView.image = Images.excludeCircleArrow.withRenderingMode(.alwaysTemplate)
  }
  
  func startAnimation(duration: Int) {
    backgroundProgressView.progressAnimation(duration: Double(duration))
  }
  
  func setRemainingTime(seconds: Int) {
    timeLabel.text = "\(seconds)"
  }
  
}
