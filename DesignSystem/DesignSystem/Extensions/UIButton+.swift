//
//  UIButton+.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation
import UIKit

public extension UIButton {
    
    func setImageForAllState(image: UIImage?) {
        self.setImage(image, for: .normal)
        self.setImage(image, for: .highlighted)
    }
    
    func configStarRate(isHighlight: Bool) {
        self.setImageForAllState(image: isHighlight
                                 ? UIImage(named: "green_star_icon", in: Bundle(for: AppTheme.self), compatibleWith: nil)
                                 : UIImage(named: "star_icon", in: Bundle(for: AppTheme.self), compatibleWith: nil))
    }
    
}
