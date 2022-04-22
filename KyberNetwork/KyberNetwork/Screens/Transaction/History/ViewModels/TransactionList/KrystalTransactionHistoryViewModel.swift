//
//  KrystalTransactionHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation

class KrystalTransactionHistoryViewModel: KNTransactionListViewModel {
  
  init(currentWallet: KNWalletObject) {
    let fetchTransactionsUseCase = KrystalFetchTransactionsUseCase()
    let fetchTokensUseCase = KrystalFetchTokensUseCase()
    super.init(fetchTransactionsUseCase: fetchTransactionsUseCase,
               fetchTokensUseCase: fetchTokensUseCase,
               wallet: currentWallet,
               isTransactionActionEnabled: false,
               canRefresh: true)
  }
  
}
