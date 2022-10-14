//
//  UIImage+kf.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import UIKit
import Kingfisher

public extension UIImageView {
    
    func loadImage(_ urlString: String?) {
      guard let urlString = urlString, let url = URL(string: urlString) else {
        return
      }
      kf.setImage(with: url)
    }
    
}
