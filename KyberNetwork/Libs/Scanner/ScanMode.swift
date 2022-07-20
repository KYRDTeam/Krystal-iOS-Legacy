//
//  ScanMode.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 08/07/2022.
//

import Foundation

enum ScanMode {
  case qr
  case text
  
  var title: String {
    switch self {
    case .qr:
      return "QR"
    case .text:
      return "Text"
    }
  }
}
