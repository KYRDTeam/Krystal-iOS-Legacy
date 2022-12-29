//
//  WalletUtils.swift
//  KrystalWallets
//
//  Created by Tung Nguyen on 26/07/2022.
//

import Foundation
import WalletCore

public class WalletUtils {
  
  public static func string(fromPrivateKey key: PrivateKey, addressType: KAddressType) -> String {
    switch addressType {
    case .evm:
      return key.data.hexString
    case .solana:
      let publicKey = key.getPublicKeyEd25519()
      let privateKeyData = key.data
      let publicKeyData = publicKey.data
      
      let data = privateKeyData + publicKeyData
      let keyPairString = Base58.encodeNoCheck(data: data)
      return keyPairString
    }
  }
    
    public static func isAddressValid(address: String, addressType: KAddressType) -> Bool {
      return WalletManager.shared.validateAddress(address: address, forAddressType: addressType)
    }
  
}
