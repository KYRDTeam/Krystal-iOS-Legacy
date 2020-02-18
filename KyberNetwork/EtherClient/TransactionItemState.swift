// Copyright SIX DAY LLC. All rights reserved.

import Foundation

enum TransactionState: Int {
    case completed
    case pending
    case error
    case failed
    case unknown

    init(int: Int) {
        self = TransactionState(rawValue: int) ?? .unknown
    }
}

enum TransactionType: Int {
  case normal
  case cancel
  case speedup

  init(int: Int) {
    self = TransactionType(rawValue: int) ?? .normal
  }
}
