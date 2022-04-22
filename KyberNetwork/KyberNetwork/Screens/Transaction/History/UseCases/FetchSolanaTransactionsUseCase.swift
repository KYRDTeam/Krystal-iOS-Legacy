//
//  FetchSolanaTransactionsUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class FetchSolanaTransactionsUseCase: FetchTransactionsUseCase, FetchNextTransactionsPageUseCase {
  static let limit = 5
  var address: String
  let krystalService = KrystalService()
  
  init(address: String) {
    self.address = address
  }
  
  func execute(completion: @escaping ([TransactionHistoryItem]) -> ()) {
    krystalService.getSolanaTransactions(address: address, prevHash: nil, limit: FetchSolanaTransactionsUseCase.limit) { result in
      switch result {
      case .success(let transactions):
        completion(transactions)
      case .failure:
        completion([])
      }
    }
  }
  
  func loadNextPage(prevHash: String, completion: @escaping ([TransactionHistoryItem], Bool) -> ()) {
    krystalService.getSolanaTransactions(address: address, prevHash: prevHash, limit: FetchSolanaTransactionsUseCase.limit) { result in
      switch result {
      case .success(let transactions):
        completion(transactions, transactions.count == FetchSolanaTransactionsUseCase.limit)
      case .failure:
        completion([], false)
      }
    }
  }
  
}
