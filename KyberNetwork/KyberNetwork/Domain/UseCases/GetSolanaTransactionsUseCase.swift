//
//  GetSolanaTransactionsUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/04/2022.
//

import Foundation

class GetSolanaTransactionsUseCase {
  let limit = 5
  
  var address: String
  let repository: TransactionRepository
  
  init(address: String, repository: TransactionRepository) {
    self.address = address
    self.repository = repository
  }
  
  func loadCachedTransactions(completion: @escaping ([SolanaTransaction]) -> ()) {
    completion(repository.getSavedSolanaTransactions())
  }
  
  func load(lastHash: String?, completion: @escaping ([SolanaTransaction], Bool) -> ()) {
    repository.fetchSolanaTransaction(address: "59FjBbHSQUe4LpzMLVFQCQ4ArDs3cMN2g7csW9U8AFtA", prevHash: lastHash, limit: limit) { transactions in
      completion(transactions, transactions.count == self.limit)
    }
  }
}
