//
//  InternalFetchTransactionsUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class FetchInternalTransactionsUseCase: FetchTransactionsUseCase {
  
  func execute(completion: @escaping ([TransactionHistoryItem]) -> ()) {
    completion( EtherscanTransactionStorage.shared.getHandledInternalHistoryTransactionForUnsupportedApi())
  }
  
}
