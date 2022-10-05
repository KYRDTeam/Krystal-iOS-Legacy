// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt
import KrystalWallets

enum AddNewWalletType {
  case full
  case onlyReal
  case watch
  case chain(chainType: ChainType)
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
    let presenter = self.parentViewController.tabBarController ?? parentViewController
    self.navigationController.popToRootViewController(animated: false)
    switch type {
    case .full, .onlyReal:
      let popup = AddWalletViewController()
      popup.delegate = self
      presenter.present(self.navigationController, animated: false) {
        self.navigationController.pushViewController(popup, animated: true)
      }
    case .watch:
      let coordinator = AddWatchWalletCoordinator(parentViewController: presenter, editingAddress: nil)
      coordinator.start()
    case .chain(let chainType):
      let coordinator = CreateChainWalletMenuCoordinator(parentViewController: navigationController, chainType: chainType, delegate: self)
      coordinate(coordinator: coordinator)
    }
  }

  fileprivate func createNewWallet(chain: ChainType = KNGeneralProvider.shared.currentChain) {
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
    self.importWalletCoordinator.start()
  }

  func didImportWallet(wallet: KWallet, chain: ChainType) {
    self.newWallet = wallet
    // Check if first wallet
    if !KNGeneralProvider.shared.isCreatedPassCode {
      KNGeneralProvider.shared.currentChain = chain
      self.passcodeCoordinator.start()
    } else {
      navigationController.dismiss(animated: true) {
        AppDelegate.shared.coordinator.switchWallet(wallet: wallet, chain: chain)
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
      AppDelegate.shared.coordinator.switchWallet(wallet: wallet, chain: KNGeneralProvider.shared.currentChain)
    }
  }
}

extension KNAddNewWalletCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidSendRefCode(_ code: String) {
    sendRefCode(address: AppDelegate.session.address, code: code)
  }
  
  func createWalletCoordinatorDidCreateWallet(_ wallet: KWallet?, name: String?, chain: ChainType) {
    guard let wallet = wallet else { return }
    didImportWallet(wallet: wallet, chain: chain)
  }

  func createWalletCoordinatorDidClose() {
  }
}

extension KNAddNewWalletCoordinator: KNImportWalletCoordinatorDelegate {
  
  func importWalletCoordinatorDidImport(watchAddress: KAddress, chain: ChainType) {
    AppDelegate.shared.coordinator.switchToWatchAddress(address: watchAddress, chain: chain)
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
      self.createNewWallet()
    case .importWallet:
      self.importAWallet()
    case .importWatchWallet:
      navigationController.dismiss(animated: true) {
        let coordinator = AddWatchWalletCoordinator(parentViewController: self.navigationController, editingAddress: nil)
        coordinator.start()
      }
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
