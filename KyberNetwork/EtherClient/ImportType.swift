// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import TrustCore

enum ImportType {
    case keystore(string: String, password: String)
    case privateKey(privateKey: String)
    case mnemonic(words: [String], password: String)
    case watch(address: Address)
}

extension ImportType {
  func displayString() -> String {
    switch self {
    case .keystore:
      return "json"
    case .privateKey:
      return "privatekey"
    case .mnemonic:
      return "seeds"
    case .watch:
      return "watch"
    }
  }
}

extension ImportType {
  func toStorageType() -> StorageType {
    switch self {
    case .keystore(let string, let password):
      return .json
    case .privateKey(let privateKey):
      return .privateKey
    case .mnemonic(let words, let password):
      return .seeds
    case .watch(let address):
      return .watch
    }
  }
}
