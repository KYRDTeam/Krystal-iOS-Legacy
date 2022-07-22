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
    container.register(KNTransactionHistoryViewModel.self) { resolver, type in
      return KNTransactionHistoryViewModel(type: type)
    }
    container.register(SolanaTransactionListViewModel.self) { resolver, address in
      return SolanaTransactionListViewModel(
        address: address,
        getSolanaTransactionsUseCase: GetSolanaTransactionsUseCase(
          address: address.addressString,
          repository: DefaultTransactionRepository()
        )
      )
    }
    container.register(BasePendingTransactionListViewModel.self) { resolver, address in
      return BasePendingTransactionListViewModel(address: address)
    }
    container.register(KNTransactionFilterViewModel.self) { resolver, tokens, filter in
      return KNTransactionFilterViewModel(tokens: tokens, filter: filter)
    }
  }
 
}
