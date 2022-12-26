//
//  AddWatchWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 05/10/2022.
//

import Foundation
import KrystalWallets
import UIKit
import WalletCore

class AddWatchWalletCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let parentViewController: UIViewController
  var editingAddress: KAddress?
  var onCompleted: (() -> ())?
  
  init(parentViewController: UIViewController, editingAddress: KAddress?) {
    self.parentViewController = parentViewController
    self.editingAddress = editingAddress
  }
  
  func start() {
    let viewModel = AddWatchWalletViewModel()
    viewModel.address = editingAddress
    let controller = AddWatchWalletViewController(viewModel: viewModel)
    controller.delegate = self
    self.parentViewController.present(controller, animated: true, completion: nil)
    MixPanelManager.track("add_watch_wallet_pop_up_open", properties: ["screenid": "add_watch_wallet_pop_up"])
  }
  
}

extension AddWatchWalletCoordinator: AddWatchWalletViewControllerDelegate {
  
  func addWatchWalletViewControllerDidEdit(_ controller: AddWatchWalletViewController, address: KAddress, addressString: String, name: String?) {
    if address.addressString == addressString { // Update current
      var address = address
      address.addressString = addressString
      address.name = name.whenNilOrEmpty(Strings.imported)
      
      try? WalletManager.shared.updateWatchAddress(address: address)
      
      if let contact = KNContactStorage.shared.get(forPrimaryKey: addressString) {
        let newContact = contact.clone()
        newContact.name = name.whenNilOrEmpty(Strings.imported)
        KNContactStorage.shared.update(contacts: [newContact])
        self.parentViewController.showSuccessTopBannerMessage(
          with: "",
          message: Strings.editWalletSuccess,
          time: 1
        )
      }
      if AppDelegate.session.address.walletID == address.walletID {
        AppDelegate.session.refreshCurrentAddressInfo()
      }
      self.parentViewController.dismiss(animated: true, completion: nil)
      self.onCompleted?()
    } else { // Add new
      try? WalletManager.shared.removeAddress(address: address)
      self.addNewWatchWallet(address: addressString, name: name, isAdd: false)
    }
  }
  
  func addWatchWalletViewController(_ controller: AddWatchWalletViewController, didAddAddress address: String, name: String?) {
    self.addNewWatchWallet(address: address, name: name)
  }

  func addWatchWalletViewControllerDidClose(_ controller: AddWatchWalletViewController) {
    self.parentViewController.dismiss(animated: true, completion: nil)
    self.onCompleted?()
  }
  
  func addNewWatchWallet(address: String, name: String?, isAdd: Bool = true) {
    let currentChain = KNGeneralProvider.shared.currentChain
    let targetChain: ChainType? = {
        if AnyAddress.isValid(string: address, coin: .ethereum) {
            return currentChain.isEVM ? currentChain : KNGeneralProvider.shared.defaultChain
        }
        if AnyAddress.isValid(string: address, coin: .solana) {
            return .solana
        }
        return nil
    }()
    
    guard let targetChain = targetChain else {
        self.parentViewController.showSuccessTopBannerMessage(
          with: Strings.failure,
          message: Strings.invalidAddress
        )
        return
    }

    do {
      let watchAddress = try WalletManager.shared.addWatchWallet(address: address, addressType: targetChain.addressType, name: name.whenNilOrEmpty(Strings.imported))
      if isAdd {
        self.parentViewController.showSuccessTopBannerMessage(
          with: Strings.walletImported,
          message: Strings.importWalletSuccess,
          time: 1
        )
      } else {
        self.parentViewController.showSuccessTopBannerMessage(
          with: "",
          message: Strings.editWalletSuccess,
          time: 1
        )
      }
      let contact = KNContact(
        address: address,
        name: name.whenNilOrEmpty(Strings.untitled),
        chainType: watchAddress.addressType.importChainType.rawValue
      )
      KNContactStorage.shared.update(contacts: [contact])
      AppDelegate.shared.coordinator.onAddWatchAddress(address: watchAddress, chain: targetChain)
      self.parentViewController.dismiss(animated: true, completion: nil)
      self.onCompleted?()
    } catch {
      guard let error = error as? WalletManagerError else {
        self.parentViewController.showErrorTopBannerMessage(message: error.localizedDescription)
        return
      }
      switch error {
      case .duplicatedWallet:
        self.parentViewController.showErrorTopBannerMessage(message: Strings.addressExisted)
      default:
        self.parentViewController.showErrorTopBannerMessage(message: error.localizedDescription)
      }
      self.parentViewController.dismiss(animated: true, completion: nil)
      self.onCompleted?()
    }
  }
  
}
