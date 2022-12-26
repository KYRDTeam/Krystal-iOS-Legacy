//
//  AppBalanceStorage.swift
//  KyberNetwork
//
//  Created by Com1 on 09/11/2022.
//

import Foundation
import Dependencies
import BaseWallet
import BigInt

class AppBalanceStorage: BalancesStorage {
  
  func getBalance(address: String) -> BigInt? {
    let balance = BalanceStorage.shared.balanceForAddress(address)
    return BigInt(balance?.balance ?? "")
  }

}
