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
    guard let wallet = wallet, case .real(let acc) = wallet.type else { return }
    let seedResult = self.keystore.exportMnemonics(account: acc)
    guard case .success(let mnemonics) = seedResult else { return }

    self.navigationController.dismiss(animated: true) {
      var isWatchWallet = false
      var solWalletId = ""
      if case WalletType.watch(_) = wallet.type {
        isWatchWallet = true
      }
      
      if case WalletType.solana(_, _, let walletID) = wallet.type {
        solWalletId = walletID
      }

      let finalImportChainType: ImportWalletChainType = .multiChain
      var solanaAddress = ""
      
      let address = SolanaUtil.seedsToPublicKey(mnemonics)
      solanaAddress = address

      let walletObject = KNWalletObject(
        address: wallet.addressString,
        name: name ?? "Untitled",
        isBackedUp: isBackUp,
        isWatchWallet: isWatchWallet,
        chainType: finalImportChainType,
        storageType: .seeds,
        evmAddress: wallet.evmAddressString,
        solanaAddress: solanaAddress,
        walletID: solWalletId
      )
      let wallets = [walletObject]
      
      let chainType = KNGeneralProvider.shared.currentChain == .solana ? 2 : 1
      KNWalletStorage.shared.add(wallets: wallets)
      let contact = KNContact(
        address: wallet.addressString,
        name: name ?? "Untitled",
        chainType: chainType
      )
      KNContactStorage.shared.update(contacts: [contact])
      
      var newWallet = wallet
      if KNGeneralProvider.shared.currentChain == .solana {
        newWallet = walletObject.toSolanaWallet()
      }
      
      self.delegate?.addNewWalletCoordinator(add: newWallet)
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
  
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?, importType: ImportType, importMethod: StorageType, selectedChain: ChainType, importChainType: ImportWalletChainType) {
    KNGeneralProvider.shared.currentChain = selectedChain
    KNNotificationUtil.postNotification(for: kChangeChainNotificationKey, object: wallet.addressString)
    self.navigationController.dismiss(animated: true) {
      var isWatchWallet = false
      var solWalletId = ""
      if case WalletType.watch(_) = wallet.type {
        isWatchWallet = true
      }

      if case WalletType.solana(_, _, let walletID) = wallet.type {
        solWalletId = walletID
      }

      var finalImportChainType = importChainType
      var solanaAddress = ""
      
      if case .mnemonic(let words, _) = importType {
        finalImportChainType = .multiChain
        let key = words.joined(separator: " ")
        let address = SolanaUtil.seedsToPublicKey(key)
        solanaAddress = address
      }
      
      if importChainType == .solana {
        solanaAddress = wallet.addressString
      }
      
      let walletObject = KNWalletObject(
        address: wallet.addressString,
        name: name ?? "Untitled",
        isBackedUp: true,
        isWatchWallet: isWatchWallet,
        chainType: finalImportChainType,
        storageType: importMethod,
        evmAddress: wallet.evmAddressString,
        solanaAddress: solanaAddress,
        walletID: solWalletId
      )
      let wallets = [walletObject]

      KNWalletStorage.shared.add(wallets: wallets)
      
      var contacts: [KNContact] = []
      let contact = KNContact(
        address: wallet.addressString,
        name: name ?? "Untitled",
        chainType: finalImportChainType.rawValue
      )
      contacts.append(contact)
      if !solanaAddress.isEmpty && wallet.addressString != solanaAddress {
        let solContact = KNContact(
          address: solanaAddress,
          name: name ?? "Untitled",
          chainType: ImportWalletChainType.solana.rawValue// finalImportChainType.rawValue
        )
        contacts.append(solContact)
      }
      
      KNContactStorage.shared.update(contacts: contacts)
      KNGeneralProvider.shared.currentChain = selectedChain
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
        let chainType = KNGeneralProvider.shared.currentChain == .solana ? 2 : 1
        let contact = KNContact(
          address: wallet.addressString,
          name: name ?? "Untitled",
          chainType: chainType
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
