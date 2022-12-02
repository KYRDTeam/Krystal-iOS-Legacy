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
}

extension UIImage {
    convenience init?(imageName: String) {
        self.init(named: imageName, in: Bundle(for: Images.self), compatibleWith: nil)
    }
}
