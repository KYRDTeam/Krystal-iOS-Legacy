//
//  UIImageView+.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit
import Kingfisher

extension UIImageView {
  
  func loadImage(urlString: String?) {
    guard let urlString = urlString else {
      return
    }
    kf.setImage(with: URL(string: urlString))
  }
  
}
