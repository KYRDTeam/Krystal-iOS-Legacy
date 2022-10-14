//
//  CircularArrowProgressView.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit
import Utilities

public class CircularArrowProgressView: BaseXibView {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var backgroundProgressView: CircularProgressView!
    @IBOutlet weak var excludeImageView: UIImageView!
    
    public override func commonInit() {
        super.commonInit()
        
        excludeImageView.image = UIImage(named: "progress_exclude")?.withRenderingMode(.alwaysTemplate)
    }
    
    public func startAnimation(duration: Int) {
        backgroundProgressView.progressAnimation(duration: Double(duration))
    }
    
    public func setRemainingTime(seconds: Int) {
        timeLabel.text = "\(seconds)"
    }
    
}
