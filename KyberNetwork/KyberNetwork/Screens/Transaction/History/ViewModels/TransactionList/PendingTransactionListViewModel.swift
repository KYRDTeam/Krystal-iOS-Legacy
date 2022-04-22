//
//  PendingTransactionHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 21/04/2022.
//

import Foundation

class PendingTransactionListViewModel: KNTransactionListViewModel {
  
  init(currentWallet: KNWalletObject) {
    let fetchTransactionsUseCase = FetchInternalPendingTransactionsUseCase()
    let fetchTokensUseCase = FetchInternalTokensUseCase()
    super.init(fetchTransactionsUseCase: fetchTransactionsUseCase,
               fetchTokensUseCase: fetchTokensUseCase,
               wallet: currentWallet,
               isTransactionActionEnabled: true,
               canRefresh: false)
  }
  
}
