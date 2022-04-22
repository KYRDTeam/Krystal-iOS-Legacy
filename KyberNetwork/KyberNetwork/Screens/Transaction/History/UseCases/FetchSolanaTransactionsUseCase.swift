//
//  FetchSolanaTransactionsUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class FetchSolanaTransactionsUseCase: FetchTransactionsUseCase {
  var address: String
  let krystalService = KrystalService()
  
  init(address: String) {
    self.address = address
  }
  
  func execute(completion: @escaping ([TransactionHistoryItem]) -> ()) {
    krystalService.getSolanaTransactions(address: address, page: 1) { result in
      switch result {
      case .success(let transactions):
        completion(transactions)
      case .failure:
        completion([])
      }
    }
  }
  
}
