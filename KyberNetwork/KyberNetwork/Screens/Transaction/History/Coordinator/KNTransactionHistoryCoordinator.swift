//
//  KNTransactionHistoryCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import UIKit

class KNTransactionHistoryCoordinator: BaseCoordinator {
  
  let navigationController: UINavigationController
  let wallet: KNWalletObject
  let type: KNTransactionHistoryType
  
  var viewController: KNTransactionHistoryViewController?
  
  init(navigationController: UINavigationController, wallet: KNWalletObject, type: KNTransactionHistoryType) {
    self.navigationController = navigationController
    self.wallet = wallet
    self.type = type
  }
  
  override func start() {
    let vc = DIContainer.resolve(KNTransactionHistoryViewController.self, arguments: wallet, type)!
    vc.viewModel.actions = KNTransactionHistoryViewModelActions(closeTransactionHistory: closeTransactionHistory, openTransactionFilter: openTransactionFilter)
    self.viewController = vc
    self.navigationController.pushViewController(vc, animated: true)
  }
  
  private func closeTransactionHistory() {
    navigationController.popViewController(animated: true)
  }
  
  private func openTransactionFilter(tokens: [String], filter: KNTransactionFilter) {
    let vc = DIContainer.resolve(KNTransactionFilterViewController.self, arguments: filter, tokens, viewController as KNTransactionFilterViewControllerDelegate?)!
    navigationController.pushViewController(vc, animated: true)
  }
  
}
