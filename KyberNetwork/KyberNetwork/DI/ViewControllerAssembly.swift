//
//  ViewControllerAssembly.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import Swinject

class ViewControllerAssembly: Assembly {
  
  func assemble(container: Container) {
    container.register(KNTransactionHistoryViewController.self) { (resolver: Resolver, wallet: KNWalletObject, type: KNTransactionHistoryType) in
      let vc = KNTransactionHistoryViewController.instantiateFromNib()
      let vm = resolver.resolve(KNTransactionHistoryViewModel.self, arguments: wallet, type)
      vc.viewModel = vm
      return vc
    }
    container.register(KNTransactionFilterViewController.self) { (resolver: Resolver, filter: KNTransactionFilter, allTokens: [String], delegate: KNTransactionFilterViewControllerDelegate?) in
      let viewModel = resolver.resolve(KNTransactionFilterViewModel.self, arguments: allTokens, filter)!
      let vc = KNTransactionFilterViewController(viewModel: viewModel)
      vc.delegate = delegate
      return vc
    }
  }
  
}
