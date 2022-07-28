//
//  TextDetector.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 08/07/2022.
//

import Foundation
import UIKit

protocol TextDetector {
  func detect(cgImage: CGImage, completion: @escaping ([String]) -> ())
}
