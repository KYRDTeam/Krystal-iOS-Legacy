//
//  TextDetector.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 08/07/2022.
//

import Foundation
import AVFoundation

protocol TextDetector {
  func detect(buffer: CMSampleBuffer, completion: @escaping ([String]) -> ())
}
