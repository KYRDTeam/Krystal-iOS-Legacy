//
//  KNTransactionHistoryCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import UIKit
import BigInt
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnectSwift
import KrystalWallets

class KNTransactionHistoryCoordinator: NSObject, Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  let type: KNTransactionHistoryType
  weak var delegate: KNHistoryCoordinatorDelegate?
  
  var viewController: KNTransactionHistoryViewController?
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  var session: KNSession {
    return AppDelegate.session
  }
  
  init(navigationController: UINavigationController, type: KNTransactionHistoryType) {
    self.navigationController = navigationController
    self.type = type
  }
  
  func start() {
    let vc = DIContainer.resolve(KNTransactionHistoryViewController.self, argument: type)!
    
    vc.viewModel.actions = KNTransactionHistoryViewModelActions(
      closeTransactionHistory: closeTransactionHistory,
      openTransactionFilter: openTransactionFilter,
      openTransactionDetail: openTransactionDetail,
      openPendingTransactionDetail: openPendingTransactionDetail,
      openSwap: openSwap,
      speedupTransaction: speedupTransaction,
      cancelTransaction: cancelTransaction,
      openWalletSelectPopup: openWalletSelectPopup
    )
    
    self.viewController = vc
    self.navigationController.pushViewController(vc, animated: true)
  }
  
  private func closeTransactionHistory() {
    navigationController.popViewController(animated: true)
  }
  
  private func openWalletSelectPopup() {
    let viewModel = WalletsListViewModel()
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
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
    if navigationController.tabBarController?.selectedIndex == 1 {
      navigationController.popToRootViewController(animated: true)
    } else {
      navigationController.tabBarController?.selectedIndex = 1
    }
  }
  
  private func speedupTransaction(transaction: InternalHistoryTransaction) {
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

    viewModel.transaction = transaction
    viewModel.isSpeedupMode = true
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.navigationController.present(vc, animated: true, completion: nil)
  }
  
  private func cancelTransaction(transaction: InternalHistoryTransaction) {
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
  
}

extension KNTransactionHistoryCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    handleGasFeePopupEvent(event: event)
  }
  
}

extension KNTransactionHistoryCoordinator: KNTransactionStatusPopUpDelegate {
  
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    handleTransactionStatusPopUpEvent(event: action)
  }
  
}

extension KNTransactionHistoryCoordinator: GasFeePopupDelegateCoordinator {

  func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
  }
  
  func handleTransactionStatusPopUpEvent(event: KNTransactionStatusPopUpEvent) {
    switch event {
    case .openLink(let url):
      self.navigationController.openSafari(with: url)
    case .speedUp(let tx):
      self.speedupTransaction(transaction: tx)
    case .cancel(let tx):
      self.cancelTransaction(transaction: tx)
    case .backToInvest:
      self.navigationController.popToRootViewController(animated: true)
    case .goToSupport:
      self.navigationController.openSafari(with: "https://docs.krystal.app/")
    default:
      break
    }
  }
}

extension KNTransactionHistoryCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.historyCoordinatorDidSelectManageWallet()
    case .didSelect(let address):
      return
    case .addWallet:
      self.delegate?.historyCoordinatorDidSelectAddWallet()
    }
  }
}

extension KNTransactionHistoryCoordinator: QRCodeReaderDelegate {
  
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let url = WCURL(result) else {
        self.navigationController.showTopBannerView(
          with: Strings.invalidSession,
          message: Strings.invalidSessionTryOtherQR,
          time: 1.5
        )
        return
      }

      do {
        let privateKey = try WalletManager.shared.exportPrivateKey(address: self.currentAddress)
        DispatchQueue.main.async {
          let controller = KNWalletConnectViewController(
            wcURL: url,
            pk: privateKey
          )
          self.navigationController.present(controller, animated: true, completion: nil)
        }
      } catch {
        self.navigationController.showTopBannerView(
          with: Strings.privateKeyError,
          message: Strings.canNotGetPrivateKey,
          time: 1.5
        )
      }
    }
  }
}
