// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt
import KrystalWallets
import AppState

enum AddNewWalletType {
  case full
  case onlyReal
  case watch
  case chain(chainType: ChainType)
}

protocol KNAddNewWalletCoordinatorDelegate: class {
  func addNewWalletCoordinator(didAdd wallet: KWallet, chain: ChainType)
  func addNewWalletCoordinator(didAdd watchAddress: KAddress, chain: ChainType)
  func addNewWalletCoordinator(remove wallet: KWallet)
}

class KNAddNewWalletCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let parentViewController: UIViewController
  let navigationController: UINavigationController
  var createWalletCoordinator: KNCreateWalletCoordinator?
  private var newWallet: KWallet?
  
  lazy var importWalletCoordinator: KNImportWalletCoordinator = {
    let coordinator = KNImportWalletCoordinator(
      navigationController: self.navigationController
    )
    coordinator.delegate = self
    return coordinator
  }()
  
  lazy var passcodeCoordinator: KNPasscodeCoordinator = {
    let coordinator = KNPasscodeCoordinator(
      navigationController: self.navigationController,
      type: .setPasscode(cancellable: false)
    )
    coordinator.delegate = self
    return coordinator
  }()
  
  init(parentViewController: UIViewController, navigationController: UINavigationController = UINavigationController()) {
    self.parentViewController = parentViewController
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    let rootViewController = UIViewController()
    rootViewController.view.backgroundColor = UIColor.clear
    self.navigationController.viewControllers = [rootViewController]
    self.navigationController.modalPresentationStyle = .overCurrentContext
    self.navigationController.modalTransitionStyle = .crossDissolve
  }
  
  func start() {
    
  }
  
  func start(type: AddNewWalletType, address: KAddress? = nil) {
    self.navigationController.popToRootViewController(animated: false)
    switch type {
    case .full, .onlyReal:
      let popup = AddWalletViewController()
      popup.delegate = self
      parentViewController.present(self.navigationController, animated: false) {
        self.navigationController.pushViewController(popup, animated: true)
      }
    case .watch:
      let coordinator = AddWatchWalletCoordinator(parentViewController: parentViewController, editingAddress: nil)
      coordinator.start()
    case .chain(let chainType):
      let coordinator = CreateChainWalletMenuCoordinator(parentViewController: navigationController, chainType: chainType, delegate: self)
      coordinate(coordinator: coordinator)
    }
  }
  
  fileprivate func createNewWallet(chain: ChainType) {
    self.createWalletCoordinator = KNCreateWalletCoordinator(
      navigationController: self.navigationController,
      newWallet: nil,
      name: nil,
      targetChain: chain
    )
    self.createWalletCoordinator?.delegate = self
    self.createWalletCoordinator?.start()
  }
  
  fileprivate func importAWallet() {
//    self.importWalletCoordinator.start()
      let importVC = ImportWalletViewController.instantiateFromNib()
      self.navigationController.pushViewController(importVC, animated: true)
  }
  
  func didImportWallet(wallet: KWallet, chain: ChainType) {
    self.newWallet = wallet
    // Check if first wallet
    if !KNGeneralProvider.shared.isCreatedPassCode {
//      KNGeneralProvider.shared.currentChain = chain
      AppState.shared.updateChain(chain: chain)
      self.passcodeCoordinator.start()
    } else {
      navigationController.dismiss(animated: true) {
        AppDelegate.shared.coordinator.onAddWallet(wallet: wallet, chain: chain)
        AppState.shared.updateAddress(address: AppState.shared.currentAddress, targetChain: AppState.shared.currentChain)
      }
    }
  }
  
  func sendRefCode(address: KAddress, code: String) {
    KrystalService().sendRefCode(address: address, code) { _, message in
      AppDelegate.shared.coordinator.tabbarController.showTopBannerView(message: message)
    }
  }
  
}

extension KNAddNewWalletCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator.stop { }
  }
  
  func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator.stop { }
  }
  
  func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
    guard let wallet = self.newWallet else {
      return
    }
    navigationController.dismiss(animated: true) {
      AppDelegate.shared.coordinator.onAddWallet(wallet: wallet, chain: KNGeneralProvider.shared.currentChain)
    }
  }
}

extension KNAddNewWalletCoordinator: KNCreateWalletCoordinatorDelegate {

  func createWalletCoordinatorDidCreateWallet(coordinator: KNCreateWalletCoordinator, _ wallet: KWallet?, name: String?, chain: ChainType) {
    guard let wallet = wallet else { return }
    didImportWallet(wallet: wallet, chain: chain)
  }
  
  func createWalletCoordinatorDidClose(coordinator: KNCreateWalletCoordinator) {
    removeCoordinator(coordinator)
  }
}

extension KNAddNewWalletCoordinator: KNImportWalletCoordinatorDelegate {
  
  func importWalletCoordinatorDidImport(watchAddress: KAddress, chain: ChainType) {
    AppDelegate.shared.coordinator.onAddWatchAddress(address: watchAddress, chain: chain)
  }
  
  func importWalletCoordinatorDidImport(wallet: KWallet, chain: ChainType) {
    didImportWallet(wallet: wallet, chain: chain)
  }
  
  func importWalletCoordinatorDidClose() {
  }
}

extension KNAddNewWalletCoordinator: AddWalletViewControllerDelegate {
  func addWalletViewController(_ controller: AddWalletViewController, run event: AddWalletViewControllerEvent) {
    switch event {
    case .createWallet:
        self.createNewWallet(chain: .all)
    case .importWallet:
      self.importAWallet()
    case .close:
      self.navigationController.dismiss(animated: false)
    }
  }
}

extension KNAddNewWalletCoordinator: CreateChainWalletMenuCoordinatorDelegate {
  
  func onSelectCreateNewWallet(chain: ChainType) {
    createNewWallet(chain: chain)
  }
  
  func onSelectImportWallet() {
    importAWallet()
  }
  
}
