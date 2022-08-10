//
//  SwapV2Coordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/08/2022.
//

import Foundation
import UIKit
import QRCodeReaderViewController
import WalletConnectSwift
import KrystalWallets

protocol SwapV2CoordinatorDelegate: AnyObject {
  func didSelectManageWallets()
  func didSelectAddWallet()
  func didSelectAddWalletForChain(chain: ChainType)
}

class SwapV2Coordinator: NSObject, Coordinator {
  var coordinators: [Coordinator] = []
  var rootViewController: SwapV2ViewController!
  var navigationController: UINavigationController!
  weak var delegate: SwapV2CoordinatorDelegate?
  
  var historyCoordinator: Coordinator?
  
  func start() {
    let vc = SwapV2ViewController.instantiateFromNib()
    let viewModel = SwapV2ViewModel(
      actions: SwapV2ViewModelActions(
        onSelectSwitchChain: {
          self.openSwitchChain()
        },
        onSelectSwitchWallet: {
          self.openSwitchWallet()
        },
        onSelectOpenHistory: {
          self.openTransactionHistory()
        }
      )
    )
    vc.viewModel = viewModel
    self.rootViewController = vc
    self.navigationController = UINavigationController(rootViewController: vc)
  }

  func openTransactionHistory() {
    switch KNGeneralProvider.shared.currentChain {
    case .solana:
      let coordinator = KNTransactionHistoryCoordinator(navigationController: navigationController, type: .solana)
      coordinator.delegate = self
      self.historyCoordinator = coordinator
      coordinate(coordinator: coordinator)
    default:
      let coordinator = KNHistoryCoordinator(navigationController: self.navigationController)
      coordinator.delegate = self
      self.historyCoordinator = coordinator
      coordinate(coordinator: coordinator)
    }
  }
  
  func openSwitchChain() {
    let popup = SwitchChainViewController()
    popup.completionHandler = { [weak self] selectedChain in
      let addresses = WalletManager.shared.getAllAddresses(addressType: selectedChain.addressType)
      if addresses.isEmpty {
        self?.delegate?.didSelectAddWalletForChain(chain: selectedChain)
        return
      } else {
        let viewModel = SwitchChainWalletsListViewModel(selected: selectedChain)
        let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
        self?.rootViewController.present(secondPopup, animated: true, completion: nil)
      }
    }
    self.rootViewController.present(popup, animated: true, completion: nil)
  }
  
  func openSwitchWallet() {
    let viewModel = WalletsListViewModel()
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }
  
  func openWalletConnect() {
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = self
    self.navigationController.present(qrcode, animated: true, completion: nil)
  }
  
}

extension SwapV2Coordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      self.openWalletConnect()
    case .manageWallet:
      self.delegate?.didSelectManageWallets()
    case .didSelect:
      return
    case .addWallet:
      self.delegate?.didSelectAddWallet()
    }
  }
}

extension SwapV2Coordinator: QRCodeReaderDelegate {
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
        let currentAddress = self.rootViewController.viewModel.currentAddress.value
        let privateKey = try WalletManager.shared.exportPrivateKey(address: currentAddress)
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

extension SwapV2Coordinator: KNHistoryCoordinatorDelegate {
  
  func historyCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.didSelectAddWalletForChain(chain: chainType)
  }
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    // No need to handle
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.didSelectAddWallet()
  }

  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.didSelectManageWallets()
  }

  func historyCoordinatorDidClose() {
    removeCoordinator(historyCoordinator!)
    historyCoordinator = nil
  }
  
}
