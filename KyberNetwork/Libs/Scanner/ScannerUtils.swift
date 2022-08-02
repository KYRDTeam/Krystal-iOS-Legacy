//
//  ScanTarget.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 20/07/2022.
//

import Foundation
import WalletCore
import WalletConnectSwift
import KrystalWallets

enum ScanResultType: CaseIterable {
  case walletConnect
  case ethPublicKey
  case ethPrivateKey
  case solPublicKey
  case solPrivateKey
  
  var trackingOutputKey: String {
    switch self {
    case .walletConnect:
      return "wallet_connect"
    case .ethPublicKey, .solPublicKey:
      return "public_key"
    case .ethPrivateKey, .solPrivateKey:
      return "private_key"
    }
  }
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
        .replacingOccurrences(of: "ethereum:", with: "")
    case .solPublicKey, .solPrivateKey:
      return text.trimmed.replacingOccurrences(of: " ", with: "")
    default:
      return text
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
      return SolanaUtils.isValidSolanaPrivateKey(text: text)
    }
  }
  
}
