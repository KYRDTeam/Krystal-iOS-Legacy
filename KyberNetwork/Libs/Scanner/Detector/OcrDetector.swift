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

class OcrDetector: TextDetector {
  
  let textRecognizer = TextRecognizer.textRecognizer()
  
  func detect(buffer: CMSampleBuffer, completion: @escaping ([String]) -> Void) {
    let visionImage = VisionImage(buffer: buffer)
    visionImage.orientation = .up
    
    textRecognizer.process(visionImage) { result, error in
      guard let result = result else { return }
      let resultText = result.text
      for block in result.blocks {
        let blockText = block.text
        let blockLanguages = block.recognizedLanguages
        let blockCornerPoints = block.cornerPoints
        let blockFrame = block.frame
        for line in block.lines {
          let lineText = line.text
          let lineLanguages = line.recognizedLanguages
          print(lineText)
        }
      }
    }
  }
  
  func convert(ciimage: CIImage) -> UIImage {
    let context = CIContext(options: nil)
    let cgImage = context.createCGImage(ciimage, from: ciimage.extent)!
    let image = UIImage(cgImage: cgImage)
    return image
  }
  
}
