//
//  QRCodeReaderDelegate.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/08/2022.
//

import Foundation
import QRCodeReaderViewController

class KQRCodeReaderDelegate: NSObject, QRCodeReaderDelegate {
  var onResult: (String) -> ()
  
  init(onResult: @escaping (String) -> ()) {
    self.onResult = onResult
  }
  
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }
  
  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.onResult(result)
    }
  }
  
}
