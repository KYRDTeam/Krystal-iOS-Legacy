//
//  GetSolanaTransactionsUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/04/2022.
//

import Foundation

class GetSolanaTransactionsUseCase {
  let limit = 5
  var lastHash: String?
  var address: String
  let repository: TransactionRepository
  
  init(address: String, repository: TransactionRepository) {
    self.address = address
    self.repository = repository
  }
  
  func loadCachedTransactions(completion: @escaping ([SolanaTransaction]) -> ()) {
    completion(repository.getSavedSolanaTransactions())
  }
  
  func load(completion: @escaping ([SolanaTransaction], Bool) -> ()) {
    repository.fetchSolanaTransaction(address: "cqDeXT4WUEUSgVGwbydDj6S8o9waG7a1zchLcDmg8Tq", prevHash: lastHash, limit: limit) { [weak self] transactions in
      guard let self = self else { return }
      self.lastHash = transactions.last?.txHash
      completion(transactions, transactions.count == self.limit)
    }
  }
}
