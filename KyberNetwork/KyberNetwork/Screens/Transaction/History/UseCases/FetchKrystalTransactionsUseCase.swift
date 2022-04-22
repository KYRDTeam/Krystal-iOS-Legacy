//
//  KrystalFetchTransactionsUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class FetchKrystalTransactionsUseCase: FetchTransactionsUseCase {
  
  func execute() -> [TransactionHistoryItem] {
    return EtherscanTransactionStorage.shared.getKrystalTransaction()
  }
  
}
