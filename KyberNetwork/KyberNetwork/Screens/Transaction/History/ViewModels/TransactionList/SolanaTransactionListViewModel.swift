//
//  SolanaTransactionListViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class SolanaTransactionListViewModel: KNTransactionListViewModel {
  
  init(currentWallet: KNWalletObject) {
    let fetchTransactionsUseCase = FetchSolanaTransactionsUseCase(address: "cqDeXT4WUEUSgVGwbydDj6S8o9waG7a1zchLcDmg8Tq") //currentWallet.address)
    let fetchTokensUseCase = FetchSolanaTokensUseCase()
    super.init(fetchTransactionsUseCase: fetchTransactionsUseCase,
               fetchTokensUseCase: fetchTokensUseCase,
               wallet: currentWallet,
               isTransactionActionEnabled: false,
               canRefresh: true)
  }
  
}

extension KrystalSolanaTransaction: TransactionHistoryItem {
  
  var txDate: Date {
    return Date(timeIntervalSince1970: Double(blockTime))
  }
  
  func match(filter: KNTransactionFilter, allTokens: [String]) -> Bool {
    return true
  }
  
  func toViewModel() -> TransactionHistoryItemViewModelProtocol {
    return KrystalSolanaTransactionItemViewModel(transaction: self)
  }
  
}
