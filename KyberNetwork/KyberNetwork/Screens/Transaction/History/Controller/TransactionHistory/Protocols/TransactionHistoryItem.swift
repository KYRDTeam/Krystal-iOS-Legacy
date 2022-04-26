//
//  TransactionHistoryItem.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation

protocol TransactionHistoryItem {
  var txDate: Date { get }
  var txHash: String { get }
  
  func toViewModel() -> TransactionHistoryItemViewModelProtocol
  
  func toDetailViewModel() -> TransactionDetailsViewModel
}

