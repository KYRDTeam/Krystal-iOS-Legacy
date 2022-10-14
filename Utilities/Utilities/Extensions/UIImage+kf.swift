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
    
    func setImage(urlString: String, symbol: String, _ size: CGSize? = nil) {
        if let url =  URL(string: urlString) {
            self.kf.setImage(with: url, placeholder: UIImage(named: "default_token"), options: [.cacheMemoryOnly])
        } else {
            DispatchQueue.main.async {
                self.image = UIImage(named: "default_token")
            }
        }
    }
}
