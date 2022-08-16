//
//  SwapError.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 16/08/2022.
//

import Foundation
import Result

enum SwapError: Error {
  case sameSourceDestToken
  case approvalFailed(error: AnyError)
}

extension SwapError {
  
  var title: String {
    switch self {
    case .sameSourceDestToken:
      return Strings.unsupported
    case .approvalFailed:
      return Strings.transactionFailed
    }
  }
  
  var message: String {
    switch self {
    case .sameSourceDestToken:
      return Strings.canNotSwapSameToken
    case .approvalFailed(let error):
      return error.prettyError
    }
  }
  
}
