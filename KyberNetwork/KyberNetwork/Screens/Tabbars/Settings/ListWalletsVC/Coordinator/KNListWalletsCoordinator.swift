// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustCore

protocol KNListWalletsCoordinatorDelegate: class {
  func listWalletsCoordinatorDidClickBack()
  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: Wallet)
  func listWalletsCoordinatorDidSelectWallet(_ wallet: Wallet)
  func listWalletsCoordinatorShouldBackUpWallet(_ wallet: KNWalletObject)
  func listWalletsCoordinatorDidUpdateWalletObjects()
  func listWalletsCoordinatorDidSelectAddWallet(type: AddNewWalletType)
}

class KNListWalletsCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []
  var addWalletCoordinator: KNAddNewWalletCoordinator?

  weak var delegate: KNListWalletsCoordinatorDelegate?

  fileprivate var selectedWallet: KNWalletObject!

  lazy var rootViewController: KNListWalletsViewController = {
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = listWallets.first! //TODO: removed current select logc
    let viewModel = KNListWalletsViewModel(listWallets: listWallets, curWallet: curWallet, keyStore: self.session.keystore)
    let controller = KNListWalletsViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.addressString
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

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
//    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
//    if let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.addressString.lowercased() }) {
//
//      DispatchQueue.global(qos: .background).async {
//        self.rootViewController.updateView(
//          with: listWallets,
//          currentWallet: curWallet
//        )
//      }
//
//    }
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }
  
  func startEditWallet() {
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.availableWalletObjects
    let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.addressString.lowercased() })!
    self.selectedWallet = curWallet
    if !curWallet.isWatchWallet {
      let viewModel = KNEditWalletViewModel(wallet: curWallet)
      let controller = KNEditWalletViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true)
    } else {
      let coordinator = KNAddNewWalletCoordinator(keystore: self.session.keystore)
      coordinator.delegate = self
      self.navigationController.present(coordinator.navigationController, animated: true) {
        coordinator.start(type: .watch, wallet: curWallet)
        self.addWalletCoordinator = coordinator
      }
    }
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }

  func updateNewSession(_ session: KNSession) {
    self.session = session
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    if let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.addressString.lowercased() }) {
      self.rootViewController.updateView(
        with: listWallets,
        currentWallet: curWallet
      )
    }
  }
}

extension KNListWalletsCoordinator: KNListWalletsViewControllerDelegate {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent) {
    switch event {
    case .close:
      self.listWalletsViewControllerDidClickBackButton()
    case .select(let wallet):
      guard let wal = self.session.keystore.matchWithWalletObject(wallet) else {
        return
      }
      self.listWalletsViewControllerDidSelectWallet(wal)
    case .remove(let wallet):
      self.showDeleteWallet(wallet)
    case .edit(let wallet):
      self.selectedWallet = wallet
      if !wallet.isWatchWallet {
        let viewModel = KNEditWalletViewModel(wallet: wallet)
        let controller = KNEditWalletViewController(viewModel: viewModel)
        controller.loadViewIfNeeded()
        controller.delegate = self
        self.navigationController.pushViewController(controller, animated: true)
      } else {
        let coordinator = KNAddNewWalletCoordinator(keystore: self.session.keystore)
        coordinator.delegate = self
        self.navigationController.present(coordinator.navigationController, animated: true) {
          coordinator.start(type: .watch, wallet: wallet)
          self.addWalletCoordinator = coordinator
        }
      }
    case .addWallet(let type):
      self.delegate?.listWalletsCoordinatorDidSelectAddWallet(type: type)
    case .copy(data: let data):
      let vm = CopyAddressViewModel(data: data, keyStore: self.session.keystore)
      let vc = CopyAddressViewController(viewModel: vm)
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: true)
    }
  }

  fileprivate func listWalletsViewControllerDidClickBackButton() {
    self.delegate?.listWalletsCoordinatorDidClickBack()
  }

  fileprivate func listWalletsViewControllerDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.listWalletsCoordinatorDidSelectWallet(wallet)
  }

  fileprivate func listWalletsViewControllerDidSelectRemoveWallet(_ wallet: Wallet) {
    let alertController = KNPrettyAlertController(
      title: "Delete".toBeLocalised(),
      message: NSLocalizedString("do.you.want.to.remove.this.wallet", value: "Do you want to remove this wallet?", comment: ""),
      secondButtonTitle: "OK".toBeLocalised(),
      firstButtonTitle: "Cancel".toBeLocalised(),
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
    case .update(let newWallet):
      self.navigationController.popViewController(animated: true) {
        self.shouldUpdateWallet(newWallet)
      }
    case .backup(let wallet):
      self.showBackUpWallet(wallet)
    case .delete(let wallet):
      self.showDeleteWallet(wallet)
    }
  }

  fileprivate func shouldUpdateWallet(_ walletObject: KNWalletObject) {
    let contact = KNContact(
      address: walletObject.address,
      name: walletObject.name,
      chainType: walletObject.chainType
    )
    KNContactStorage.shared.update(contacts: [contact])
    KNWalletStorage.shared.update(wallets: [walletObject])
    let wallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = wallets.first(where: { $0.address.lowercased() == self.session.wallet.addressString.lowercased() })!
    self.rootViewController.updateView(
      with: KNWalletStorage.shared.wallets,
      currentWallet: curWallet
    )
    self.delegate?.listWalletsCoordinatorDidUpdateWalletObjects()
  }

  fileprivate func showBackUpWallet(_ wallet: KNWalletObject) {
    self.delegate?.listWalletsCoordinatorShouldBackUpWallet(wallet)
  }

  fileprivate func deleteSolWallet(_ wallet: KNWalletObject) {
    let address = wallet.address
    let walletID = wallet.walletID
    KNWalletStorage.shared.delete(walletAddress: address)
    self.session.keystore.solanaUtil.removeWallet(walletID: walletID)
    if address == self.session.wallet.addressString, let next = KNWalletStorage.shared.solanaWallet.last {
      let solWal = Wallet(type: .solana(next.address, next.evmAddress, next.walletID))
      self.listWalletsViewControllerDidSelectWallet(solWal)
    } else {
      self.rootViewController.coordinatorDidUpdateWalletsList()
    }
  }

  fileprivate func showDeleteWallet(_ wallet: KNWalletObject) {
    if wallet.chainType == 2 {
      if let wal = self.session.keystore.wallets.first(where: { $0.addressString.lowercased() == wallet.evmAddress.lowercased() }) {
        self.listWalletsViewControllerDidSelectRemoveWallet(wal)
      } else {
        let alertController = KNPrettyAlertController(
          title: "Delete".toBeLocalised(),
          message: NSLocalizedString("do.you.want.to.remove.this.wallet", value: "Do you want to remove this wallet?", comment: ""),
          secondButtonTitle: "OK".toBeLocalised(),
          firstButtonTitle: "Cancel".toBeLocalised(),
          secondButtonAction: {
            if self.navigationController.topViewController is KNEditWalletViewController {
              self.navigationController.popViewController(animated: true, completion: {
                self.deleteSolWallet(wallet)
              })
            } else {
              self.deleteSolWallet(wallet)
            }
          },
          firstButtonAction: nil
        )
        self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
      }
    } else {
      guard let wal = self.session.keystore.wallets.first(where: { $0.addressString.lowercased() == wallet.address.lowercased() }) else {
        if wallet.address.lowercased() == self.session.wallet.addressString.lowercased(), let next = self.session.keystore.wallets.last {
          self.listWalletsViewControllerDidSelectWallet(next)
        }
        KNWalletStorage.shared.delete(wallet: wallet)
        self.rootViewController.coordinatorDidUpdateWalletsList()
        return
      }
      self.listWalletsViewControllerDidSelectRemoveWallet(wal)
    }
    
  }
}

extension KNListWalletsCoordinator: KNEnterWalletNameViewControllerDelegate {
  func enterWalletNameDidNext(sender: KNEnterWalletNameViewController, walletObject: KNWalletObject) {
    KNWalletStorage.shared.update(wallets: [walletObject])
    let wallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = wallets.first(where: { $0.address.lowercased() == self.session.wallet.addressString })!
    self.rootViewController.updateView(
      with: KNWalletStorage.shared.wallets,
      currentWallet: curWallet
    )
    self.delegate?.listWalletsCoordinatorDidUpdateWalletObjects()
  }
}

extension KNListWalletsCoordinator: KNAddNewWalletCoordinatorDelegate {
  func addNewWalletCoordinator(add wallet: Wallet) {
    self.rootViewController.coordinatorDidUpdateWalletsList()
  }

  func addNewWalletCoordinator(remove wallet: Wallet) {
  }

  func addNewWalletCoordinatorDidSendRefCode(_ code: String) {
  }
}

extension KNListWalletsCoordinator: CopyAddressViewControllerDelegate {
  func copyAddressViewController(_ controller: CopyAddressViewController, didSelect wallet: WalletData, chain: ChainType) {
    print(KNWalletStorage.shared.wallets)
    let filter = chain == .solana ? KNWalletStorage.shared.get(forSolanaAddress: wallet.solanaAddress) : KNWalletStorage.shared.get(forPrimaryKey: wallet.address)
    guard let found = filter else {
      return
    }
    self.navigationController.popViewController(animated: true, completion: nil)
    var action = [UIAlertAction]()
    
    var editWallet = found
    if chain == .solana {
      editWallet = found.toSolanaWalletObject()
    }
    
    action.append(UIAlertAction(title: NSLocalizedString("edit", value: "Edit", comment: ""), style: .default, handler: { _ in
      
      
      if !wallet.isWatchWallet {
        let viewModel = KNEditWalletViewModel(wallet: editWallet)
        let controller = KNEditWalletViewController(viewModel: viewModel)
        controller.loadViewIfNeeded()
        controller.delegate = self
        self.navigationController.pushViewController(controller, animated: true)
        self.selectedWallet = editWallet
      } else {
        let coordinator = KNAddNewWalletCoordinator(keystore: self.session.keystore)
        coordinator.delegate = self
        self.navigationController.present(coordinator.navigationController, animated: true) {
          coordinator.start(type: .watch, wallet: found)
          self.addWalletCoordinator = coordinator
        }
        self.selectedWallet = found
      }
    }))
    action.append(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))

    let alertController = KNActionSheetAlertViewController(title: "", actions: action)
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}
