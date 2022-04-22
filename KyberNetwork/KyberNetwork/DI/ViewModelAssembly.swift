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
    container.register(KrystalTransactionListViewModel.self) { resolver, wallet in
      return KrystalTransactionListViewModel(currentWallet: wallet)
    }
    container.register(PendingTransactionListViewModel.self) { resolver, wallet in
      return PendingTransactionListViewModel(currentWallet: wallet)
    }
    container.register(KNTransactionFilterViewModel.self) { resolver, tokens, filter in
      return KNTransactionFilterViewModel(tokens: tokens, filter: filter)
    }
  }
 
}
