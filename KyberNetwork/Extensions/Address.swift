// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import TrustCore

enum Errors: LocalizedError {
    case invalidAddress
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return NSLocalizedString("send.error.invalidAddress", value: "Invalid Address", comment: "")
        case .invalidAmount:
            return NSLocalizedString("send.error.invalidAmount", value: "Invalid Amount", comment: "")
        }
    }
}

extension Address {
  static func isAddressValid(_ string: String) -> Bool {
    return Address(string: string) != nil
  }
}
