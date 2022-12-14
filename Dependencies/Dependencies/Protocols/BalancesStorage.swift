//
//  BalanceStorage.swift
//  Dependencies
//
//  Created by Com1 on 09/11/2022.
//

import Foundation
import BaseWallet
import Services
import BigInt

public protocol BalancesStorage {
  func getBalance(address: String) -> BigInt?
}
