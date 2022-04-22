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
    container.register(KrystalTransactionHistoryViewModel.self) { resolver, wallet in
      return KrystalTransactionHistoryViewModel(currentWallet: wallet)
    }
    container.register(PendingTransactionHistoryViewModel.self) { resolver, wallet in
      return PendingTransactionHistoryViewModel(currentWallet: wallet)
    }
    container.register(KNTransactionFilterViewModel.self) { resolver, tokens, filter in
      return KNTransactionFilterViewModel(tokens: tokens, filter: filter)
    }
  }
 
}
