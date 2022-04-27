//
//  KNTransactionHistoryCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import UIKit
import BigInt

class KNTransactionHistoryCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  var session: KNSession
  let type: KNTransactionHistoryType
  
  var viewController: KNTransactionHistoryViewController?
  
  init(navigationController: UINavigationController, session: KNSession, type: KNTransactionHistoryType) {
    self.navigationController = navigationController
    self.session = session
    self.type = type
  }
  
  func start() {
    let vc = DIContainer.resolve(KNTransactionHistoryViewController.self, arguments: session.wallet, type)!
    
    vc.viewModel.actions = KNTransactionHistoryViewModelActions(
      closeTransactionHistory: closeTransactionHistory,
      openTransactionFilter: openTransactionFilter,
      openTransactionDetail: openTransactionDetail,
      openPendingTransactionDetail: openPendingTransactionDetail,
      openSwap: openSwap,
      speedupTransaction: speedupTransaction,
      cancelTransaction: cancelTransaction
    )
    
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
  
  private func openTransactionDetail(transaction: TransactionHistoryItem) {
    let coordinator = KNTransactionDetailsCoordinator(navigationController: navigationController, viewModel: transaction.toDetailViewModel())
    coordinate(coordinator: coordinator)
  }
  
  private func openPendingTransactionDetail(transaction: InternalHistoryTransaction) {
    let coordinator = KNTransactionDetailsCoordinator(navigationController: navigationController, viewModel: transaction.toDetailViewModel())
    coordinate(coordinator: coordinator)
  }
  
  private func openSwap() {
    //    let coordinator = KNExchangeTokenCoordinator(navigationController: navigationController, session: session)
    //    coordinate(coordinator: coordinator)
  }
  
  private func speedupTransaction(transaction: InternalHistoryTransaction) {
    let gasLimit: BigInt = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return BigInt(transaction.eip1559Transaction?.gasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
      } else {
        return BigInt(transaction.transactionObject?.gasLimit ?? "") ?? BigInt(0)
      }
    }()
    
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    
    viewModel.isCancelMode = true
    viewModel.transaction = transaction
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.navigationController.present(vc, animated: true, completion: nil)
  }
  
  private func cancelTransaction(transaction: InternalHistoryTransaction) {
    let gasLimit: BigInt = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return BigInt(transaction.eip1559Transaction?.reservedGasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
      } else {
        return BigInt(transaction.transactionObject?.reservedGasLimit ?? "") ?? BigInt(0)
      }
    }()
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    
    viewModel.isSpeedupMode = true
    viewModel.transaction = transaction
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.navigationController.present(vc, animated: true, completion: nil)
  }
  
}

extension KNTransactionHistoryCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    handleGasFeePopupEvent(event: event)
  }
  
}

extension KNTransactionHistoryCoordinator: KNTransactionStatusPopUpDelegate {
  
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    handleTransactionStatusPopUpEvent(event: event)
  }
  
}

extension KNTransactionHistoryCoordinator: GasFeePopupDelegateCoordinator {
  
  func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = delegate
    self.navigationController.present(controller, animated: true, completion: nil)
  }
  
}
