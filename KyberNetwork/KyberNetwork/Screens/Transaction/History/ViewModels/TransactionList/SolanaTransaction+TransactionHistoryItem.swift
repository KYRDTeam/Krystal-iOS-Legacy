//
//  SolanaTransaction+.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation

extension SolanaTransaction: TransactionHistoryItem {
  
  var txDate: Date {
    return Date(timeIntervalSince1970: Double(blockTime))
  }
  
  func toViewModel() -> TransactionHistoryItemViewModelProtocol {
    return SolanaTransactionItemViewModel(transaction: self)
  }
  
  func toDetailViewModel() -> TransactionDetailsViewModel {
    return SolanaTransactionDetailViewModel(transaction: self)
  }
  
}

