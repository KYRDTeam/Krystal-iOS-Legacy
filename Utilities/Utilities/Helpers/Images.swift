//
//  Images.swift
//  Utilities
//
//  Created by Com1 on 02/12/2022.
//

import UIKit

class Images {
    static let blueTickIcon = UIImage(imageName: "blueTick_icon")
    static let greenCheckedIcon = UIImage(imageName: "green-checked-icon")
    static let warningTagIcon = UIImage(imageName: "warning-tag-icon")
}

extension UIImage {
    convenience init?(imageName: String) {
        self.init(named: imageName, in: Bundle(for: Images.self), compatibleWith: nil)
    }
}
