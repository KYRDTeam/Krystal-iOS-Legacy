//
//  SignerFactory.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 09/06/2022.
//

import Foundation
import KrystalWallets

class SignerFactory {
  
  func getSigner(address: KAddress) -> KSignerProtocol {
    switch address.addressType {
    case .evm:
      return EthSigner()
    case .solana:
      return SolanaSigner()
    }
  }
  
}
