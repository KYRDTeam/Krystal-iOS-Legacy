//
//  TransactionHistoryItem.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation

protocol TransactionHistoryItem {
  var txDate: Date { get }
  
  func match(filter: KNTransactionFilter, allTokens: [String]) -> Bool
  func toViewModel() -> TransactionHistoryItemViewModelProtocol
}

