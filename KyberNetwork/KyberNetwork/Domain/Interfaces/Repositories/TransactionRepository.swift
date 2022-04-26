//
//  TransactionRepository.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/04/2022.
//

import Foundation

protocol TransactionRepository {
  func saveSolanaTransactions(transactions: [SolanaTransaction])
  func getSavedSolanaTransactions() -> [SolanaTransaction]
  func fetchSolanaTransaction(
    address: String, prevHash: String?, limit: Int,
    completion: @escaping ([SolanaTransaction]) -> ()
  )
}
