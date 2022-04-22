//
//  KrystalTransactionHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation

class KrystalTransactionListViewModel: KNTransactionListViewModel {
  
  init(currentWallet: KNWalletObject) {
    let fetchTransactionsUseCase = FetchKrystalTransactionsUseCase()
    let fetchTokensUseCase = FetchKrystalTokensUseCase()
    super.init(fetchTransactionsUseCase: fetchTransactionsUseCase,
               fetchTokensUseCase: fetchTokensUseCase,
               wallet: currentWallet,
               isTransactionActionEnabled: false,
               canRefresh: true,
               canLoadMore: false)
  }
  
}
