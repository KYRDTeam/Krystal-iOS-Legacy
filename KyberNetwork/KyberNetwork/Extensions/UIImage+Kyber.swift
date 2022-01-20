// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import JdenticonSwift
import Kingfisher

extension UIImage {

  static let imageCache = NSCache<AnyObject, AnyObject>()

  static func generateQRCode(from string: String) -> UIImage? {
    let context = CIContext()
    let data = string.data(using: String.Encoding.ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
      filter.setValue(data, forKey: "inputMessage")
      let transform = CGAffineTransform(scaleX: 7, y: 7)
      if let output = filter.outputImage?.transformed(by: transform), let cgImage = context.createCGImage(output, from: output.extent) {
        return UIImage(cgImage: cgImage)
      }
    }
    return nil
  }

  static func generateImage(with size: CGFloat, hash: Data) -> UIImage? {
    guard let cgImage = IconGenerator(size: size, hash: hash).render() else { return nil }
    return UIImage(cgImage: cgImage)
  }

  var noir: UIImage? {
    let context = CIContext(options: nil)
    guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
    currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
    if let output = currentFilter.outputImage,
      let cgImage = context.createCGImage(output, from: output.extent) {
      return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    return nil
  }

  func resizeImage(to newSize: CGSize?) -> UIImage? {
    guard let size = newSize else {
      return self
    }
    if self.size == size { return self }

    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    self.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage ?? self
  }

  func compress(to expectedMb: CGFloat) -> UIImage? {
    let sizeInBytes = expectedMb * 1024.0 * 1024.0
    var needCompress: Bool = true
    var compressingValue: CGFloat = 1.0
    var imageData: Data?
    while needCompress && compressingValue > 0.0 {
      if let data = self.jpegData(compressionQuality: compressingValue) {
        if CGFloat(data.count) < sizeInBytes {
          needCompress = false
          imageData = data
        } else {
          compressingValue -= 0.1
        }
      } else {
        return self
      }
    }
    guard let data = imageData ?? self.jpegData(compressionQuality: 0.0) else { return self }
    return UIImage(data: data)
  }
  
  static func loadImageIconWithCache(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
    guard let url = URL(string: urlString) else {
      completion(UIImage(named: "tagview_default_icon"))
      return
    }
    let downloader = ImageDownloader.default
    downloader.downloadImage(with: url) { result in
        switch result {
        case .success(let value):
          completion(value.image)
        case .failure:
          completion(UIImage(named: "tagview_default_icon"))
        }
    }
  }
}
