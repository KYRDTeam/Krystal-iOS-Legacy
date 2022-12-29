//
//  UIImage+kf.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import UIKit
import Kingfisher

let VERIFIED_TAG   = "VERIFIED"
let PROMOTION_TAG  = "PROMOTION"
let SCAM_TAG       = "SCAM"
let UNVERIFIED_TAG = "UNVERIFIED"

public extension UIImageView {
    
    func loadImage(_ urlString: String?, placeholder: UIImage? = nil) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        kf.setImage(with: url, placeholder: placeholder)
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
  
    func setSymbolImage(symbol: String?, size: CGSize? = nil) {
      guard let symbol = symbol else {
        self.image = UIImage(named: "default_token")!
        return
      }
      
      let icon = symbol.lowercased()
      let image = UIImage(named: icon.lowercased())
      let placeHolderImg = image ?? UIImage(named: "default_token")!
      var url = "https://files.kyberswap.com/DesignAssets/tokens/iOS/\(icon).png"
      self.setImage(urlString: url, symbol: symbol, size)
    }
}

public extension UIImage {
    static func imageWithTag(tag: String) -> UIImage? {
      if tag == VERIFIED_TAG {
          return Images.blueTickIcon
      } else if tag == PROMOTION_TAG {
          return Images.greenCheckedIcon
      } else if tag == SCAM_TAG {
         return Images.warningTagIcon
      } else if tag == UNVERIFIED_TAG {
         return nil
      }
      return nil
    }
}
