//
//  SolanaUtils.swift
//  KrystalWallets
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import WalletCore

public class SolanaUtils {
  
  public static func isValidSolanaPrivateKey(text: String) -> Bool {
    return isNormalPrivateKey(text: text) || getPrivateKey(numericPrivateKey: text) != nil
  }
  
  public static func isNormalPrivateKey(text: String) -> Bool {
    if text.count == 64 { // Trust private key
      guard let data = Data(hexString: text) else {
        return false
      }
      return data.count == 32
    } else {
      guard let data = Base58.decodeNoCheck(string: text) else {
        return false
      }
      return data.count == 64
    }
  }
  
  public static func getPrivateKey(numericPrivateKey: String) -> PrivateKey? {
    let bytes = numericPrivateKey
                  .replacingOccurrences(of: "[", with: "")
                  .replacingOccurrences(of: "]", with: "")
                  .split(separator: ",")
                  .compactMap { UInt8($0) }
    guard bytes.count == 64 else {
      return nil
    }
    return PrivateKey(data: Data(bytes[0...31]))
  }
  
}
