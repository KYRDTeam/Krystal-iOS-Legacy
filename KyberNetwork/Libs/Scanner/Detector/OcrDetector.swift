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
import Vision

class OcrDetector: TextDetector {
  
  let textRecognizer = TextRecognizer.textRecognizer()
  
  func detect(cgImage: CGImage, completion: @escaping ([String]) -> Void) {
      let requestHandler = VNImageRequestHandler(cgImage: cgImage)
      let request = VNRecognizeTextRequest(completionHandler: { request, error in
          guard let observations = request.results as? [VNRecognizedTextObservation] else {
              return
          }
          let recognizedStrings = observations.compactMap { observation in
              return observation.topCandidates(1).first?.string
          }
          
          completion(recognizedStrings)
      })
      
      do {
          // Perform the text-recognition request.
          try requestHandler.perform([request])
      } catch {
          print("Unable to perform the requests: \(error).")
      }
      
//    let visionImage = VisionImage(image: UIImage(cgImage: cgImage))
//    textRecognizer.process(visionImage) { result, _ in
//      guard let result = result else {
//        return
//      }
//      let texts = result.blocks.map { block -> String in
//        let blockText = block.lines.map { $0.text }.joined()
//        return blockText
//      }
//      completion(texts)
//    }
  }
}
