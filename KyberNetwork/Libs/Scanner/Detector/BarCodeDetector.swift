//
//  BarCodeDetector.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 08/07/2022.
//

import Foundation
import AVFoundation
import Vision
import CoreImage

class BarCodeDetector: TextDetector {
  
  func detect(cgImage: CGImage, completion: @escaping ([String]) -> Void) {
    let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage)
    let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, _ in
      let observations = request.results?.compactMap { $0 as? VNBarcodeObservation } ?? []
      completion(observations.compactMap { $0.payloadStringValue })
    })
    do {
      try imageRequestHandler.perform([barcodeRequest])
    } catch {
      print(error)
    }
  }
  
  func detect(buffer: CMSampleBuffer, completion: @escaping ([String]) -> Void) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
      return
    }
    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
    let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, _ in
      let observations = request.results?.compactMap { $0 as? VNBarcodeObservation } ?? []
      completion(observations.compactMap { $0.payloadStringValue })
    })
    do {
      try imageRequestHandler.perform([barcodeRequest])
    } catch {
      print(error)
    }
  }
  
}
