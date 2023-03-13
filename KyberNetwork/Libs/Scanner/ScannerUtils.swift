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
  case promotionCode
  case seed
  
  var trackingOutputKey: String {
    switch self {
    case .walletConnect:
      return "wallet_connect"
    case .ethPublicKey, .solPublicKey:
      return "public_key"
    case .ethPrivateKey, .solPrivateKey:
      return "private_key"
    case .promotionCode:
      return "promotion_code"
    case .seed:
      return "seed"

    }
  }
}

class ScannerUtils {
  
  static func formattedText(text: String, forType type: ScanResultType) -> String {
    switch type {
    case .ethPublicKey:
      return text.trimmed
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "l", with: "1")
        .replacingOccurrences(of: "o", with: "0")
        .replacingOccurrences(of: "O", with: "0")
        .replacing(pattern: "@.*")
        .replacing(pattern: ".*:")
    case .ethPrivateKey:
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
    case .promotionCode:
      return getPromotionCode(text: text) != nil
    case .seed:
      return true
//      var words = text.trimmed.components(separatedBy: " ").map({ $0.trimmed })
//      words = words.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
//      let validWordCount = [12, 15, 18, 21, 24]
//      return validWordCount.contains(words.count)
    }
  }
  
  static func getPromotionCode(text: String) -> String? {
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    let pattern1 = #"promo:(?<code>.+)"#
    let regex1 = try! NSRegularExpression(pattern: pattern1, options: [])
    let matches1 = regex1.matches(in: text, range: range)
    
    let pattern2 = #"https://.+/promo/(?<code>.+)"#
    let regex2 = try! NSRegularExpression(pattern: pattern2, options: [])
    let matches2 = regex2.matches(in: text, range: range)
    
    let match1 = matches1.first.flatMap {
      Range($0.range(withName: "code")).map { range in text.substring(with: range) }
    }
    let match2 = matches2.first.flatMap {
      Range($0.range(withName: "code")).map { range in text.substring(with: range) }
    }
    return match1 ?? match2
  }
}
