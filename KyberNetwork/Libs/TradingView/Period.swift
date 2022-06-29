//
//  Period.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 27/06/2022.
//

import Foundation

enum Period {
  case h1
  case h4
  case d1
  case d7
  case M1
  case M3
  case Y1
  
  var interval: String {
    switch self {
    case .h1:
      return "60"
    case .h4:
      return "240"
    case .d1:
      return "1D"
    case .d7:
      return "7D"
    case .M1:
      return "M"
    case .M3:
      return "3M"
    case .Y1:
      return "Y"
    }
  }
}
