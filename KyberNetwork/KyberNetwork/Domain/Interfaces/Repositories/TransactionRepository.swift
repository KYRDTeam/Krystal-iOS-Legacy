//
//  TransactionRepository.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/04/2022.
//

import Foundation

protocol TransactionRepository {
  func saveSolanaTransactions(address: String, transactions: [SolanaTransaction])
  func getSavedSolanaTransactions(address: String) -> [SolanaTransaction]
  func fetchSolanaTransaction(
    address: String, prevHash: String?, limit: Int,
    completion: @escaping ([SolanaTransaction]) -> ()
  )
}
