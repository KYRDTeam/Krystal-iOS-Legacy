//
//  EditWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 05/10/2022.
//

import Foundation
import UIKit
import KrystalWallets

class EditWalletCoordinator: Coordinator {
  
  enum EditWalletAction {
    case delete
  }
  
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  let wallet: KWallet
  let addressType: KAddressType
  var currentAction: EditWalletAction?
  var rootViewController: UIViewController!
  
  var onCompleted: ((_ hasUpdate: Bool) -> ())?
  
  init(navigationController: UINavigationController, wallet: KWallet, addressType: KAddressType) {
    self.navigationController = navigationController
    self.wallet = wallet
    self.addressType = addressType
  }
  
  func start() {
    let actions = KNEditWalletViewModel.Actions { [weak self] in
      self?.navigationController.popViewController(animated: true)
      self?.onCompleted?(false)
    } updateName: { [weak self] newName in
      self?.updateWallet(name: newName)
      self?.navigationController.popViewController(animated: true)
      self?.onCompleted?(true)
    } backup: { [weak self] in
      self?.openExportWallet()
    } delete: { [weak self] in
      self?.showDeleteWalletAlert()
    }
    let viewModel = KNEditWalletViewModel(wallet: wallet, addressType: addressType, actions: actions)
    let controller = KNEditWalletViewController(viewModel: viewModel)
    self.rootViewController = controller
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  func showDeleteWalletAlert() {
    rootViewController.showConfirmAlert(title: "", message: Strings.deleteWalletConfirmMessage) { [weak self] in
      self?.showAuthPasscode(action: .delete)
    }
  }
  
  func openExportWallet() {
    let coordinator = ExportWalletCoordinator(navigationController: navigationController, wallet: wallet, addressType: addressType)
    coordinate(coordinator: coordinator)
  }
  
  func showAuthPasscode(action: EditWalletAction) {
    self.currentAction = action
    let passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
    passcodeCoordinator.delegate = self
    coordinate(coordinator: passcodeCoordinator)
  }
  
  func updateWallet(name: String) {
    let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
    let contacts = addresses.map { address -> KNContact in
      let chainType = address.addressType.importChainType.rawValue
      return KNContact(address: address.addressString, name: name, chainType: chainType)
    }
    KNContactStorage.shared.update(contacts: contacts)
    try? WalletManager.shared.renameWallet(wallet: wallet, newName: name)
    if AppDelegate.session.address.walletID == wallet.id {
      AppDelegate.session.refreshCurrentAddressInfo()
    }
  }
  
}

extension EditWalletCoordinator: KNPasscodeCoordinatorDelegate {
  
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
      case .delete:
        try? WalletManager.shared.remove(wallet: self.wallet)
        self.navigationController.popViewController(animated: true, completion: nil)
        self.onCompleted?(true)
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
