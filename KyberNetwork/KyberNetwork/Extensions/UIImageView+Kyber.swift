// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIImageView {
  func  setImage(with url: URL, placeholder: UIImage?, size: CGSize? = nil, applyNoir: Bool = false, fitSize: CGSize? = nil, failCompletion: (() -> Void)? = nil) {
    if let cachedImg = UIImage.imageCache.object(forKey: url as AnyObject) as? UIImage {
      if let needTofit = fitSize {
        let widthRatio = needTofit.width / cachedImg.size.width
        if widthRatio < 1 {
          let imageWidth = widthRatio * cachedImg.size.width
          let imageHeight = widthRatio * cachedImg.size.height
          self.image = cachedImg.resizeImage(to: CGSize(width: imageWidth, height: imageHeight))
        } else {
          self.image = applyNoir ? cachedImg.resizeImage(to: size)?.noir : cachedImg.resizeImage(to: size)
        }
      } else {
        self.image = applyNoir ? cachedImg.resizeImage(to: size)?.noir : cachedImg.resizeImage(to: size)
      }

      self.layoutIfNeeded()
      return
    }
    self.image = applyNoir ? placeholder?.resizeImage(to: size)?.noir : placeholder?.resizeImage(to: size)
    self.layoutIfNeeded()
    URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
      guard let `self` = self else { return }
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          UIImage.imageCache.setObject(image, forKey: url as AnyObject)
          if let needTofit = fitSize {
            let widthRatio = needTofit.width / image.size.width
            if widthRatio > 1 {
              let imageWidth = widthRatio * image.size.width
              let imageHeight = widthRatio * image.size.height
              self.image = image.resizeImage(to: CGSize(width: imageWidth, height: imageHeight))
            } else {
              self.image = applyNoir ? image.resizeImage(to: size)?.noir : image.resizeImage(to: size)
            }
          } else {
            self.image = applyNoir ? image.resizeImage(to: size)?.noir : image.resizeImage(to: size)
          }
          
          self.layoutIfNeeded()
        }
      } else {
        if let failCompletion = failCompletion {
          failCompletion()
        }
      }
    }.resume()
  }

  func setImage(with urlString: String, placeholder: UIImage?, size: CGSize? = nil, applyNoir: Bool = false, fitSize: CGSize? = nil) {
    guard let url = URL(string: urlString) else {
      self.image = applyNoir ? placeholder?.resizeImage(to: size)?.noir : placeholder?.resizeImage(to: size)
      self.layoutIfNeeded()
      return
    }
    self.setImage(with: url, placeholder: placeholder, size: size, applyNoir: applyNoir, fitSize: fitSize)
  }

  func setTokenImage(
    token: TokenObject,
    size: CGSize? = nil
    ) {
    if !token.isSupported {
      self.image = UIImage(named: "default_token")
      self.layoutIfNeeded()
      return
    }
    let icon = token.icon.isEmpty ? token.symbol.lowercased() : token.icon
    let image = UIImage(named: icon.lowercased())
    let placeHolderImg = image ?? UIImage(named: "default_token")!
    self.setImage(
      with: token.iconURL,
      placeholder: placeHolderImg,
      size: size
    )
  }

  func setTokenImage(
    tokenData: TokenData,
    size: CGSize? = nil
    ) {
    guard let url = URL(string: tokenData.logo)  else {
      self.setSymbolImage(symbol: tokenData.symbol)
      return
    }
    self.setImage(with: url, placeholder: UIImage(named: "default_token"), size: size) {
      self.setSymbolImage(symbol: tokenData.symbol)
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
    if let token = KNSupportedTokenStorage.shared.getTokenWith(symbol: symbol) {
      url = token.logo
    }
    self.setImage(
      with: url,
      placeholder: placeHolderImg,
      size: size
    )
  }
  
  func setImage(urlString: String, symbol: String, _ size: CGSize? = nil) {
    guard let url = URL(string: urlString)  else {
      self.image = UIImage(named: "default_token")!
      return
    }
    self.setImage(with: url, placeholder: UIImage(named: "default_token"), size: size) {
      self.setSymbolImage(symbol: symbol)
    }
  }
}
