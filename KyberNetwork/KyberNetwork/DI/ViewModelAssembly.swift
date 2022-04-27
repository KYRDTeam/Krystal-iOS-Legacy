//
//  ViewModelAssembly.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 21/04/2022.
//

import Foundation
import Swinject

class ViewModelAssembly: Assembly {
  
  func assemble(container: Container) {
    container.register(KNTransactionHistoryViewModel.self) { resolver, wallet, type in
      return KNTransactionHistoryViewModel(currentWallet: wallet, type: type)
    }
    container.register(SolanaTransactionListViewModel.self) { resolver, wallet in
      return SolanaTransactionListViewModel(
        wallet: wallet,
        getSolanaTransactionsUseCase: GetSolanaTransactionsUseCase(
          address: wallet.address,
          repository: DefaultTransactionRepository()
        )
      )
    }
    container.register(BasePendingTransactionListViewModel.self) { resolver, wallet in
      return BasePendingTransactionListViewModel(wallet: wallet)
    }
    container.register(KNTransactionFilterViewModel.self) { resolver, tokens, filter in
      return KNTransactionFilterViewModel(tokens: tokens, filter: filter)
    }
  }
 
}
