//
//  KAddress+Equatable.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 12/06/2022.
//

import Foundation
import KrystalWallets

extension KAddress: Equatable {
  
  public static func == (lhs: KAddress, rhs: KAddress) -> Bool {
    return lhs.addressString == rhs.addressString && lhs.isWatchWallet == rhs.isWatchWallet && lhs.addressType == rhs.addressType
  }
  
}
