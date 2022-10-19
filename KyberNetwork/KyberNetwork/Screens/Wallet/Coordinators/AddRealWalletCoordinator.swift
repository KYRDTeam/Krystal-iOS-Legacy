//
//  AddRealWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 06/10/2022.
//

import Foundation
import UIKit
import KrystalWallets

class AddRealWalletCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let parentViewController: UIViewController
  let navigationController: UINavigationController
  let targetChain: ChainType
  let addWalletViewController: AddWalletViewController
  
  var onCompleted: (() -> ())?
  
  init(parentViewController: UIViewController, targetChain: ChainType = KNGeneralProvider.shared.currentChain) {
    self.addWalletViewController = AddWalletViewController()
    self.parentViewController = parentViewController
    self.navigationController = UINavigationController()
    self.navigationController.setNavigationBarHidden(true, animated: false)
    let rootViewController = UIViewController()
    rootViewController.view.backgroundColor = UIColor.clear
    self.navigationController.viewControllers = [rootViewController]
    self.navigationController.modalPresentationStyle = .fullScreen
    self.navigationController.modalTransitionStyle = .crossDissolve
    self.targetChain = targetChain
    self.addWalletViewController.delegate = self
  }
  
  func start() {
    parentViewController.present(self.navigationController, animated: false) {
      self.navigationController.pushViewController(self.addWalletViewController, animated: true)
    }
  }
}

extension AddRealWalletCoordinator: KNCreateWalletCoordinatorDelegate {
  
  func createWalletCoordinatorDidCreateWallet(coordinator: KNCreateWalletCoordinator, _ wallet: KWallet?, name: String?, chain: ChainType) {
    removeCoordinator(coordinator)
    if let wallet = wallet {
      AppDelegate.shared.coordinator.onAddWallet(wallet: wallet, chain: targetChain)
    }
    self.navigationController.dismiss(animated: false) {
      self.onCompleted?()
    }
  }
  
  func createWalletCoordinatorDidClose(coordinator: KNCreateWalletCoordinator) {
    removeCoordinator(coordinator)
  }
  
}

extension AddRealWalletCoordinator: AddWalletViewControllerDelegate {
  
  func openCreateNewWallet() {
    let coordinator = KNCreateWalletCoordinator(navigationController: navigationController, newWallet: nil, name: nil, targetChain: targetChain)
    coordinator.delegate = self
    coordinate(coordinator: coordinator)
  }
  
  func openImportWallet() {
    
  }
  
  func addWalletViewController(_ controller: AddWalletViewController, run event: AddWalletViewControllerEvent) {
    switch event {
    case .createWallet:
      self.openCreateNewWallet()
    case .importWallet:
      self.openImportWallet()
    case .close:
      self.navigationController.dismiss(animated: false) {
        self.onCompleted?()
      }
    }
  }
  
}
