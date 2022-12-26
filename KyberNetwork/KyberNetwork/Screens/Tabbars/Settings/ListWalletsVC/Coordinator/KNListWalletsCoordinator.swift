// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KrystalWallets

class KNListWalletsCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var addWalletCoordinator: KNAddNewWalletCoordinator?
  
  var onCompleted: (() -> ())?
  
  enum WalletListAction {
    case deleteWallet(wallet: KWallet)
    case deleteAddress(address: KAddress)
  }

  var currentAction: WalletListAction?

  lazy var rootViewController: KNListWalletsViewController = {
    let viewModel = KNListWalletsViewModel()
    let controller = KNListWalletsViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  func start() {
    MixPanelManager.track("manage_wallet_open", properties: ["screenid": "manage_wallet"])
    self.observeNotifications()
    self.navigationController.pushViewController(rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true, completion: nil)
  }

  func observeNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidSwitchAddress),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  @objc func appDidSwitchAddress() {
    self.rootViewController.reloadData()
  }

  func showAuthPasscode(action: WalletListAction) {
    self.currentAction = action
    let passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
    passcodeCoordinator.delegate = self
    coordinate(coordinator: passcodeCoordinator)
  }
  
}

extension KNListWalletsCoordinator: KNListWalletsViewControllerDelegate {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent) {
    switch event {
    case .close:
      stop()
    case .open(let wallet):
      let vm = CopyAddressViewModel(wallet: wallet)
      let vc = CopyAddressViewController(viewModel: vm)
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: true)
      MixPanelManager.track("multi_chain_wallets_open", properties: ["screenid": "multi_chain_wallets"])
    case .removeWallet(let wallet):
      self.showDeleteWalletAlert {
        self.showAuthPasscode(action: .deleteWallet(wallet: wallet))
      }
    case .removeWatchAddress(let address):
      self.showDeleteWalletAlert {
        try? WalletManager.shared.removeAddress(address: address)
        self.rootViewController.reloadData()
        AppDelegate.shared.coordinator.onRemoveWatchAddress(address: address)
      }
    case .editWatchAddress(let address):
      let coordinator = AddWatchWalletCoordinator(parentViewController: navigationController, editingAddress: address)
      coordinator.onCompleted = { [weak self] in
        self?.removeCoordinator(coordinator)
      }
      coordinate(coordinator: coordinator)
    case .editWallet(let wallet, let addressType):
      let coordinator = EditWalletCoordinator(navigationController: navigationController, wallet: wallet, addressType: addressType)
      coordinate(coordinator: coordinator)
      MixPanelManager.track("edit_wallet_open", properties: ["screenid": "edit_wallet"])
    case .addWallet(let type):
      switch type {
      case .watch:
        let coordinator = AddWatchWalletCoordinator(parentViewController: navigationController, editingAddress: nil)
        coordinator.onCompleted = { [weak self] in
          self?.removeCoordinator(coordinator)
          self?.rootViewController.reloadData()
        }
        coordinate(coordinator: coordinator)
      default:
        let coordinator = KNAddNewWalletCoordinator(parentViewController: navigationController)
        coordinator.start(type: type)
        addCoordinator(coordinator)
      }
    }
  }

  fileprivate func listWalletsViewControllerDidClickBackButton() {
    self.onCompleted?()
  }

}

extension KNListWalletsCoordinator {

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
        AppDelegate.shared.coordinator.onRemoveWallet(wallet: wallet)
        return
      },
      firstButtonAction: nil
    )
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
  }
}

extension KNListWalletsCoordinator: CopyAddressViewControllerDelegate {
  func copyAddressViewController(_ controller: CopyAddressViewController, didSelect wallet: KWallet, chain: ChainType) {
    self.navigationController.popViewController(animated: true, completion: nil)
    
    var action = [UIAlertAction]()
    action.append(UIAlertAction(title: Strings.edit, style: .default, handler: { [weak self] _ in
      self?.openEditWallet(wallet: wallet, chain: chain)
    }))
    action.append(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))

    let alertController = KNActionSheetAlertViewController(title: "", actions: action)
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
  
  func openEditWallet(wallet: KWallet, chain: ChainType) {
    if let address = WalletManager.shared.address(walletID: wallet.id, addressType: chain.addressType) {
      if address.isWatchWallet {
        let coordinator = AddWatchWalletCoordinator(parentViewController: navigationController, editingAddress: address)
        coordinator.onCompleted = { [weak self] in
          self?.removeCoordinator(coordinator)
        }
        coordinate(coordinator: coordinator)
      } else {
        let coordinator = EditWalletCoordinator(navigationController: navigationController, wallet: wallet, addressType: chain.addressType)
        coordinator.onCompleted = { [weak self] _ in
          self?.removeCoordinator(coordinator)
        }
        coordinate(coordinator: coordinator)
      }
    }
    
  }
}

extension KNListWalletsCoordinator: KNPasscodeCoordinatorDelegate {
  
  func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
    coordinator.stop {
      self.removeCoordinator(coordinator)
      self.currentAction = nil
    }
  }
  
  func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
    coordinator.stop {
      self.removeCoordinator(coordinator)
      switch self.currentAction {
      case .deleteWallet(let wallet):
        try? WalletManager.shared.remove(wallet: wallet)
        self.rootViewController.reloadData()
        AppDelegate.shared.coordinator.onRemoveWallet(wallet: wallet)
      case .deleteAddress(let address):
        try? WalletManager.shared.removeAddress(address: address)
        self.rootViewController.reloadData()
        AppDelegate.shared.coordinator.onRemoveWatchAddress(address: address)
      default:
        return
      }
    }
  }
  
  func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
    coordinator.stop {
      self.removeCoordinator(coordinator)
    }
  }
  
}
