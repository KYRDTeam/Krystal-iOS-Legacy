//
//  PendingTransactionHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 21/04/2022.
//

import Foundation

class PendingTransactionHistoryViewModel: KNTransactionListViewModel {
  
  init(currentWallet: KNWalletObject) {
    let fetchTransactionsUseCase = InternalPendingFetchTransactionsUseCase()
    let fetchTokensUseCase = InternalFetchTokensUseCase()
    super.init(fetchTransactionsUseCase: fetchTransactionsUseCase,
               fetchTokensUseCase: fetchTokensUseCase,
               wallet: currentWallet,
               isTransactionActionEnabled: true,
               canRefresh: false)
  }
  
}
