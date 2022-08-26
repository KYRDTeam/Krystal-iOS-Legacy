// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KrystalWallets

protocol KNListWalletsCoordinatorDelegate: class {
  func listWalletsCoordinatorDidClickBack()
  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: KWallet)
  func listWalletsCoordinatorDidRemoveWatchAddress(_ address: KAddress)
  func listWalletsCoordinatorShouldBackUpWallet(_ wallet: KWallet, addressType: KAddressType)
//  func listWalletsCoordinatorDidUpdateWalletObjects()
  func listWalletsCoordinatorDidSelectAddWallet(type: AddNewWalletType)
}

class KNListWalletsCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []
  var addWalletCoordinator: KNAddNewWalletCoordinator?

  weak var delegate: KNListWalletsCoordinatorDelegate?

  lazy var rootViewController: KNListWalletsViewController = {
    let viewModel = KNListWalletsViewModel()
    let controller = KNListWalletsViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(
    navigationController: UINavigationController,
    session: KNSession,
    delegate: KNListWalletsCoordinatorDelegate?
    ) {
    self.navigationController = navigationController
    self.session = session
    self.delegate = delegate
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }
  
  func startEditWallet() {
    let currentAddress = AppDelegate.session.address
    if currentAddress.isWatchWallet {
      let coordinator = KNAddNewWalletCoordinator()
      coordinator.delegate = self
      self.navigationController.present(coordinator.navigationController, animated: true) {
        coordinator.start(type: .watch, address: currentAddress)
        self.addWalletCoordinator = coordinator
      }
    } else {
      guard let wallet = WalletManager.shared.wallet(forAddress: currentAddress) else {
        return
      }
      let viewModel = KNEditWalletViewModel(wallet: wallet, addressType: KNGeneralProvider.shared.currentChain.addressType)
      let controller = KNEditWalletViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true)
    }
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }

  func appDidSwitchAddress() {
    self.rootViewController.reloadData()
  }

}

extension KNListWalletsCoordinator: KNListWalletsViewControllerDelegate {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent) {
    switch event {
    case .close:
      self.listWalletsViewControllerDidClickBackButton()
    case .open(let wallet):
      let vm = CopyAddressViewModel(wallet: wallet)
      let vc = CopyAddressViewController(viewModel: vm)
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: true)
    case .removeWallet(let wallet):
      self.showDeleteWalletAlert {
        self.delegate?.listWalletsCoordinatorDidSelectRemoveWallet(wallet)
        self.rootViewController.reloadData()
      }
    case .removeWatchAddress(let address):
      self.showDeleteWalletAlert {
        try? WalletManager.shared.removeAddress(address: address)
        self.delegate?.listWalletsCoordinatorDidRemoveWatchAddress(address)
        self.rootViewController.reloadData()
      }
    case .editWatchAddress(let address):
      let coordinator = KNAddNewWalletCoordinator()
      coordinator.delegate = self
      self.navigationController.present(coordinator.navigationController, animated: true) {
        coordinator.start(type: .watch, address: address)
        self.addWalletCoordinator = coordinator
      }
    case .editWallet(let wallet, let addressType):
//      self.selectedWallet = wallet
      let viewModel = KNEditWalletViewModel(wallet: wallet, addressType: addressType)
      let controller = KNEditWalletViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true)
    case .addWallet(let type):
      self.delegate?.listWalletsCoordinatorDidSelectAddWallet(type: type)
    }
  }

  fileprivate func listWalletsViewControllerDidClickBackButton() {
    self.delegate?.listWalletsCoordinatorDidClickBack()
  }

  fileprivate func listWalletsViewControllerDidSelectRemoveWallet(_ wallet: KWallet) {
    let alertController = KNPrettyAlertController(
      title: Strings.delete,
      message: Strings.deleteWalletConfirmMessage,
      secondButtonTitle: Strings.ok,
      firstButtonTitle: Strings.cancel,
      secondButtonAction: {
        if self.navigationController.topViewController is KNEditWalletViewController {
          self.navigationController.popViewController(animated: true, completion: {
            self.delegate?.listWalletsCoordinatorDidSelectRemoveWallet(wallet)
          })
        } else {
          self.delegate?.listWalletsCoordinatorDidSelectRemoveWallet(wallet)
        }
      },
      firstButtonAction: nil
    )
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
  }
}

extension KNListWalletsCoordinator: KNEditWalletViewControllerDelegate {
  func editWalletViewController(_ controller: KNEditWalletViewController, run event: KNEditWalletViewEvent) {
    switch event {
    case .back: self.navigationController.popViewController(animated: true)
    case .update(let wallet, let name):
      self.navigationController.popViewController(animated: true) {
        self.updateWallet(wallet: wallet, name: name)
      }
    case .backup(let wallet, let addressType):
      self.showBackUpWallet(wallet, addressType: addressType)
    case .delete(let wallet):
      self.showDeleteWallet(wallet)
    }
  }

  fileprivate func updateWallet(wallet: KWallet, name: String) {
    let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
    let contacts = addresses.map { address -> KNContact in
      let chainType = address.addressType.importChainType.rawValue
      return KNContact(address: address.addressString, name: name, chainType: chainType)
    }
    KNContactStorage.shared.update(contacts: contacts)
    try? WalletManager.shared.renameWallet(wallet: wallet, newName: name)
    self.rootViewController.reloadData()
    if AppDelegate.session.address.walletID == wallet.id {
      AppDelegate.session.refreshCurrentAddressInfo()
    }
  }

  fileprivate func showBackUpWallet(_ wallet: KWallet, addressType: KAddressType) {
    self.delegate?.listWalletsCoordinatorShouldBackUpWallet(wallet, addressType: addressType)
  }
  
  fileprivate func showDeleteWalletAlert(onConfirm: @escaping () -> ()) {
    let alertController = KNPrettyAlertController(
      title: Strings.delete,
      message: Strings.deleteWalletConfirmMessage,
      secondButtonTitle: Strings.ok,
      firstButtonTitle: Strings.cancel,
      secondButtonAction: {
        onConfirm()
        self.rootViewController.reloadData()
        return
      },
      firstButtonAction: nil
    )
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
  }

  fileprivate func showDeleteWallet(_ wallet: KWallet) {
    let alertController = KNPrettyAlertController(
      title: Strings.delete,
      message: Strings.deleteWalletConfirmMessage,
      secondButtonTitle: Strings.ok,
      firstButtonTitle: Strings.cancel,
      secondButtonAction: {
        try? WalletManager.shared.remove(wallet: wallet)
        self.rootViewController.reloadData()
        return
      },
      firstButtonAction: nil
    )
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
  }
}

extension KNListWalletsCoordinator: KNAddNewWalletCoordinatorDelegate {
  func addNewWalletCoordinator(didAdd wallet: KWallet, chain: ChainType) {
    rootViewController.reloadData()
  }
  
  func addNewWalletCoordinator(didAdd watchAddress: KAddress, chain: ChainType) {
    rootViewController.reloadData()
  }

  func addNewWalletCoordinator(remove wallet: KWallet) {
    rootViewController.reloadData()
  }

  func addNewWalletCoordinatorDidSendRefCode(_ code: String) {
    
  }
}

extension KNListWalletsCoordinator: CopyAddressViewControllerDelegate {
  func copyAddressViewController(_ controller: CopyAddressViewController, didSelect wallet: KWallet, chain: ChainType) {
    self.navigationController.popViewController(animated: true, completion: nil)
    
    var action = [UIAlertAction]()
    action.append(UIAlertAction(title: Strings.edit, style: .default, handler: { _ in
      let viewModel = KNEditWalletViewModel(wallet: wallet, addressType: chain.addressType)
      let controller = KNEditWalletViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true)
    }))
    action.append(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))

    let alertController = KNActionSheetAlertViewController(title: "", actions: action)
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}
