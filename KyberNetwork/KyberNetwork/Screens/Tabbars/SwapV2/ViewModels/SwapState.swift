//
//  SwapState.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 09/08/2022.
//

import Foundation
import BigInt

enum SwapState {
  case emptyAmount
  case fetchingRates
  case rateNotFound
  case notConnected
  case insufficientBalance
  case checkingAllowance
  case notApproved(currentAllowance: BigInt)
  case approving
  case ready
  
  var isActiveState: Bool {
    switch self {
    case .emptyAmount, .insufficientBalance:
      return false
    default:
      return true
    }
  }
}
