//
//  TextDetector.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 08/07/2022.
//

import Foundation
import MLImage
import MLKit
import UIKit
import AVFoundation
import MLKitVision

class OcrDetector: TextDetector {
  
  let textRecognizer = TextRecognizer.textRecognizer()
  
  func detect(cgImage: CGImage, completion: @escaping ([String]) -> Void) {
    let visionImage = VisionImage(image: UIImage(cgImage: cgImage))
    textRecognizer.process(visionImage) { result, _ in
      guard let result = result else {
        return
      }
      let texts = result.blocks.map { block -> String in
        let blockText = block.lines.map { $0.text }.joined()
        return blockText
      }
      completion(texts)
    }
  }
}
