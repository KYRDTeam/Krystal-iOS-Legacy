//
//  Images.swift
//  TokenModule
//
//  Created by Com1 on 02/12/2022.
//

import UIKit

class Images {
    static let closeSearchIcon = UIImage(imageName: "close-search-icon")!
    static let searchIcon = UIImage(imageName: "search_icon")!
    static let verifyToken = UIImage(imageName: "blueTick_icon")!
    static let promotedToken = UIImage(imageName: "green-checked-tag-icon")!
    static let unverifiedToken = UIImage(imageName: "warning-tag-icon")!
    static let defaultToken = UIImage(imageName: "default_token")!
}

extension UIImage {
    convenience init?(imageName: String) {
        self.init(named: imageName, in: Bundle(for: Images.self), compatibleWith: nil)
    }
}
