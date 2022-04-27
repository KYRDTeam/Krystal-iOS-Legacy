// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import BigInt

protocol KNAddNewWalletCoordinatorDelegate: class {
  func addNewWalletCoordinator(add wallet: Wallet)
  func addNewWalletCoordinator(remove wallet: Wallet)
  func addNewWalletCoordinatorDidSendRefCode(_ code: String)
}

enum AddNewWalletType {
  case full
  case onlyReal
  case watch
}

class KNAddNewWalletCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  fileprivate var keystore: Keystore

  fileprivate var newWallet: Wallet?
  fileprivate var isCreate: Bool = false

  weak var delegate: KNAddNewWalletCoordinatorDelegate?

  lazy var createWalletCoordinator: KNCreateWalletCoordinator = {
    let coordinator = KNCreateWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore,
      newWallet: nil,
      name: nil
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var importWalletCoordinator: KNImportWalletCoordinator = {
    let coordinator = KNImportWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    keystore: Keystore
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    let rootViewController = UIViewController()
    rootViewController.view.backgroundColor = UIColor.clear
    self.navigationController.viewControllers = [rootViewController]
    self.navigationController.modalPresentationStyle = .overCurrentContext
    self.navigationController.modalTransitionStyle = .crossDissolve
    self.keystore = keystore
  }

  func start() {
    
  }
  
  func start(type: AddNewWalletType, wallet: KNWalletObject? = nil) {
    self.navigationController.popToRootViewController(animated: false)
    switch type {
    case .full, .onlyReal:
      let popup = CreateWalletMenuViewController(isFull: type == .full)
      popup.delegate = self
      self.navigationController.present(popup, animated: true, completion: {})
    case .watch:
      self.createWatchWallet(wallet)
    }
  }

  fileprivate func createNewWallet() {
    self.isCreate = true
    self.newWallet = nil
    self.createWalletCoordinator.updateNewWallet(nil, name: nil)
    self.createWalletCoordinator.start()
  }

  fileprivate func importAWallet() {
    self.isCreate = false
    self.newWallet = nil
    self.importWalletCoordinator.start()
  }

  fileprivate func createWatchWallet(_ wallet: KNWalletObject? = nil) {
    self.isCreate = false
    self.newWallet = nil
    let viewModel = AddWatchWalletViewModel()
    viewModel.wallet = wallet
    let controller = AddWatchWalletViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
  }
}

extension KNAddNewWalletCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.addNewWalletCoordinatorDidSendRefCode(code)
  }
  
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?, isBackUp: Bool) {
    guard let wallet = wallet else { return }
    self.navigationController.dismiss(animated: true) {
      var isWatchWallet = false
      if case WalletType.watch(_) = wallet.type {
        isWatchWallet = true
      }
      let walletObject = KNWalletObject(
        address: wallet.addressString,
        name: name ?? "Untitled",
        isBackedUp: isBackUp,
        isWatchWallet: isWatchWallet,
        chainType: .multiChain,
        storageType: .seeds
      )
      KNWalletStorage.shared.add(wallets: [walletObject])
      let contact = KNContact(
        address: wallet.addressString,
        name: name ?? "Untitled"
      )
      KNContactStorage.shared.update(contacts: [contact])
      self.delegate?.addNewWalletCoordinator(add: wallet)
    }
  }

  func createWalletCoordinatorDidClose() {
    self.navigationController.dismiss(animated: false, completion: nil)
  }

  func createWalletCoordinatorCancelCreateWallet(_ wallet: Wallet) {
    self.navigationController.dismiss(animated: true) {
      self.delegate?.addNewWalletCoordinator(remove: wallet)
    }
  }
}

extension KNAddNewWalletCoordinator: KNImportWalletCoordinatorDelegate {
  
  func importWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.addNewWalletCoordinatorDidSendRefCode(code)
  }
  
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?, importType: ImportWalletChainType, importMethod: StorageType) {
    self.navigationController.dismiss(animated: true) {
      //TODO: add type to wallet firebase obj
      var isWatchWallet = false
      var solWalletId = ""
      if case WalletType.watch(_) = wallet.type {
        isWatchWallet = true
      }

      if case WalletType.solana(_, _, let walletID) = wallet.type {
        solWalletId = walletID
      }
      
      let walletObject = KNWalletObject(
        address: wallet.addressString,
        name: name ?? "Untitled",
        isBackedUp: true,
        isWatchWallet: isWatchWallet,
        chainType: importType,
        storageType: importMethod,
        evmAddress: wallet.evmAddressString,
        walletID: solWalletId
      )
      var wallets = [walletObject]
      if case .multiChain = importType, case .real(let account) = wallet.type {
        let result = self.keystore.exportMnemonics(account: account)
        if case .success(let seeds) = result {
          let publicKey = SolanaUtil.seedsToPublicKey(seeds)
          let solName = name ?? "Untitled"
          let solWalletObject = KNWalletObject(
            address: publicKey,
            name: solName + "-sol",
            isBackedUp: true,
            isWatchWallet: isWatchWallet,
            chainType: .solana,
            storageType: importMethod,
            evmAddress: wallet.evmAddressString,
            walletID: solWalletId
          )
          wallets.append(solWalletObject)
        }
      }
      
      if case .solana = importType, case .solana(_ , let evmAddress, let walletID) = wallet.type {
        let walletName = name ?? "Untitled"
        let evmWalletObject = KNWalletObject(
          address: evmAddress,
          name: walletName + "-evm",
          isBackedUp: true,
          isWatchWallet: isWatchWallet,
          chainType: .evm,
          storageType: importMethod,
          evmAddress: "",
          walletID: walletID
        )
        wallets.append(evmWalletObject)
      }
      KNWalletStorage.shared.add(wallets: wallets)
      let contact = KNContact(
        address: wallet.addressString,
        name: name ?? "Untitled"
      )
      KNContactStorage.shared.update(contacts: [contact])
      self.delegate?.addNewWalletCoordinator(add: wallet)
    }
  }

  func importWalletCoordinatorDidClose() {
    self.navigationController.dismiss(animated: true, completion: nil)
  }
}

extension KNAddNewWalletCoordinator: CreateWalletMenuViewControllerDelegate {
  func createWalletMenuViewController(_ controller: CreateWalletMenuViewController, run event: CreateWalletMenuViewControllerEvent) {
    switch event {
    case .createRealWallet:
      self.createNewWallet()
    case .importWallet:
      self.importAWallet()
    case .createWatchWallet:
      self.createWatchWallet()
    case .close:
      self.navigationController.dismiss(animated: true, completion: nil)
    }
  }
}

extension KNAddNewWalletCoordinator: AddWatchWalletViewControllerDelegate {
  func addWatchWalletViewControllerDidEdit(_ controller: AddWatchWalletViewController, wallet: KNWalletObject, address: String, name: String?) {
    if wallet.address.lowercased() == address.lowercased() {
      wallet.name = name ?? "Imported"
      KNWalletStorage.shared.add(wallets: [wallet])
      if let contact = KNContactStorage.shared.get(forPrimaryKey: address) {
        let newContact = contact.clone()
        newContact.name = name ?? "Imported"
        KNContactStorage.shared.update(contacts: [newContact])
        self.navigationController.showSuccessTopBannerMessage(
          with: "",
          message: "Edit wallet successful".toBeLocalised(),
          time: 1
        )
      }
      self.navigationController.dismiss(animated: true, completion: nil)
      if KNGeneralProvider.shared.currentChain == .solana {
        self.delegate?.addNewWalletCoordinator(add: Wallet(type: .solana(wallet.address, wallet.evmAddress, wallet.walletID)))
      } else if let walletAddress = Address(string: wallet.address) {
        self.delegate?.addNewWalletCoordinator(add: Wallet(type: .watch(walletAddress)))
      }
      
    } else {
      if KNGeneralProvider.shared.currentChain == .solana {
        self.keystore.solanaUtil.removeWatchWallet(address)
        self.importNewWatchWallet(address: address, name: name, isAdd: false)
      } else {
        guard let walletAddress = Address(string: wallet.address) else {
          return
        }
        let aWallet = Wallet(type: .watch(walletAddress))
        self.keystore.delete(wallet: aWallet)
        KNWalletStorage.shared.delete(wallet: wallet)

        self.importNewWatchWallet(address: address, name: name, isAdd: false)
      }
      
    }
  }
  
  func addWatchWalletViewController(_ controller: AddWatchWalletViewController, didAddAddress address: String, name: String?) {
    self.importNewWatchWallet(address: address, name: name)
  }

  func addWatchWalletViewControllerDidClose(_ controller: AddWatchWalletViewController) {
    self.navigationController.dismiss(animated: true, completion: nil)
  }

  fileprivate func importNewWatchWallet(address: String, name: String?, isAdd: Bool = true) {
    let importType: ImportWalletChainType = KNGeneralProvider.shared.currentChain == .solana ? .solana : .evm
    self.keystore.importWallet(type: .watch(address: address, name: name ?? ""), importType: importType) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let wallet):
        if isAdd {
          self.navigationController.showSuccessTopBannerMessage(
            with: NSLocalizedString("wallet.imported", value: "Wallet Imported", comment: ""),
            message: NSLocalizedString("you.have.successfully.imported.a.wallet", value: "You have successfully imported a wallet", comment: ""),
            time: 1
          )
        } else {
          self.navigationController.showSuccessTopBannerMessage(
            with: "",
            message: "Edit wallet successful".toBeLocalised(),
            time: 1
          )
        }

        let walletName: String = {
          if name == nil || name?.isEmpty == true { return "Imported" }
          return name ?? "Imported"
        }()
        let walletObject = KNWalletObject(
          address: wallet.addressString,
          name: walletName,
          isWatchWallet: true,
          chainType: importType
        )
        KNWalletStorage.shared.add(wallets: [walletObject])
        let contact = KNContact(
          address: wallet.addressString,
          name: name ?? "Untitled"
        )
        KNContactStorage.shared.update(contacts: [contact])
        self.navigationController.dismiss(animated: true, completion: nil)
        self.delegate?.addNewWalletCoordinator(add: wallet)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(message: error.localizedDescription)
      }
    }
  }
}
