//
//  ScanTarget.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 20/07/2022.
//

import Foundation
import WalletCore
import WalletConnectSwift

enum ScanResultType: CaseIterable {
  case walletConnect
  case ethPublicKey
  case ethPrivateKey
  case solPublicKey
  case solPrivateKey
}

class ScannerUtils {
  
  static func smoothen(text: String, forType type: ScanResultType) -> String {
    switch type {
    case .ethPublicKey, .ethPrivateKey:
      return text.trimmed
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "l", with: "1")
        .replacingOccurrences(of: "o", with: "0")
        .replacingOccurrences(of: "O", with: "0")
    case .solPublicKey, .solPrivateKey:
      return text.trimmed.replacingOccurrences(of: " ", with: "")
    default:
      return text
    }
  }
  
  static func getResultType(ofText text: String) -> ScanResultType? {
    return ScanResultType.allCases.first { type in
      let formattedText = smoothen(text: text, forType: type)
      return isValid(text: formattedText, forType: type)
    }
  }
  
  static func isValid(text: String, forType type: ScanResultType) -> Bool {
    switch type {
    case .walletConnect:
      return WCURL(text) != nil
    case .ethPublicKey:
      return AnyAddress.isValid(string: text, coin: .ethereum)
    case .ethPrivateKey:
      guard let data = Data(hexString: text) else {
        return false
      }
      return PrivateKey.isValid(data: data, curve: .secp256k1)
    case .solPublicKey:
      return AnyAddress.isValid(string: text, coin: .solana)
    case .solPrivateKey:
      guard let data = Data(hexString: text) else {
        return false
      }
      return PrivateKey.isValid(data: data, curve: .ed25519)
    }
  }
  
}
