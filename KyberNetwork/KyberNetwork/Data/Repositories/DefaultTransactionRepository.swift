//
//  DefaultTransactionRepository.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation
import Moya

class DefaultTransactionRepository: TransactionRepository {
  let provider = MoyaProvider<KrystalApi>(plugins: [NetworkLoggerPlugin()])
  let storage = SolanaTransactionStorage()
  
  func saveSolanaTransactions(address: String, transactions: [SolanaTransaction]) {
    storage.saveTransactions(address: address, transactions: transactions)
  }
  
  func getSavedSolanaTransactions(address: String) -> [SolanaTransaction] {
    storage.getSolanaTransactions(address: address)
  }
  
  func fetchSolanaTransaction(
    address: String, prevHash: String?, limit: Int,
    completion: @escaping ([SolanaTransaction]) -> ()
  ) {
    provider.requestWithFilter(.transactions(address: address, prevHash: prevHash, limit: limit)) { result in
      switch result {
      case .success(let json):
        do {
          let listResponse = try JSONDecoder().decode(SolanaTransactionListDTO.self, from: json.data)
          completion(listResponse.transactions.map { $0.toDomain() })
        } catch {
          completion([])
        }
      case .failure(let error):
        completion([])
      }
    }
  }
  
}
