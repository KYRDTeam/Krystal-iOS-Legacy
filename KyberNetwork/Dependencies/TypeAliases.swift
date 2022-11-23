//
//  TypeAliases.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 18/10/2022.
//

import Foundation
import BaseModule
import TransactionModule
import BaseWallet
import Services

typealias KNBaseViewController = BaseModule.KNBaseViewController
typealias InAppBrowsingViewController = BaseModule.InAppBrowsingViewController

// Transaction Module
typealias EIP1559Transaction = TransactionModule.EIP1559Transaction
typealias SignTransaction = TransactionModule.LegacyTransaction
typealias InternalTransactionState = TransactionModule.InternalTransactionState

typealias CurrencyMode = BaseWallet.CurrencyMode
typealias Token = Services.Token

