//
//  InternalTransactionListViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class InternalTransactionListViewModel: KNTransactionListViewModel {
  
  init(currentWallet: KNWalletObject) {
    let fetchTransactionsUseCase = FetchInternalTransactionsUseCase()
    let fetchTokensUseCase = FetchInternalTokensUseCase()
    super.init(fetchTransactionsUseCase: fetchTransactionsUseCase,
               fetchTokensUseCase: fetchTokensUseCase,
               wallet: currentWallet,
               isTransactionActionEnabled: false,
               canRefresh: true,
               canLoadMore: false)
  }
  
}
