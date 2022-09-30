// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt
import KrystalWallets

protocol KNAddNewWalletCoordinatorDelegate: class {
  func addNewWalletCoordinator(didAdd wallet: KWallet, chain: ChainType)
  func addNewWalletCoordinator(didAdd watchAddress: KAddress, chain: ChainType)
  func addNewWalletCoordinator(remove wallet: KWallet)
  func addNewWalletCoordinatorDidSendRefCode(_ code: String)
}

enum AddNewWalletType {
  case full
  case onlyReal
  case watch
  case chain(chainType: ChainType)
}

class KNAddNewWalletCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController  
  weak var delegate: KNAddNewWalletCoordinatorDelegate?
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

  init(navigationController: UINavigationController = UINavigationController()) {
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
      self.navigationController.pushViewController(popup, animated: true)
    case .watch:
      self.createWatchWallet(address)
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

  fileprivate func createWatchWallet(_ address: KAddress? = nil) {
    let viewModel = AddWatchWalletViewModel()
    viewModel.address = address
    let controller = AddWatchWalletViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    MixPanelManager.track("add_watch_wallet_pop_up_open", properties: ["screenid": "add_watch_wallet_pop_up"])
  }
  
  func showCreateWalletWalletPopup(_ address: KAddress? = nil, container: UIViewController) {
    let viewModel = AddWatchWalletViewModel()
    viewModel.address = address
    let controller = AddWatchWalletViewController(viewModel: viewModel)
    controller.delegate = self
    container.present(controller, animated: true, completion: nil)
    MixPanelManager.track("add_watch_wallet_pop_up_open", properties: ["screenid": "add_watch_wallet_pop_up"])
  }
  
  func didImportWallet(wallet: KWallet, chain: ChainType) {
    self.newWallet = wallet
    // Check if first wallet
    if !KNGeneralProvider.shared.isCreatedPassCode {
      KNGeneralProvider.shared.currentChain = chain
      self.passcodeCoordinator.start()
    } else {
      navigationController.dismiss(animated: true) {
        self.delegate?.addNewWalletCoordinator(didAdd: wallet, chain: chain)
      }
    }
  }
}

extension KNAddNewWalletCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidEvaluatePIN() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidCreatePasscode() {
    guard let wallet = self.newWallet else {
      return
    }
//    guard let address = WalletManager.shared.address(forWalletID: wallet.id) else {
//      return
//    }
//    guard let chain = ChainType.allCases.first(where: { $0.addressType == address.addressType }) else {
//      return
//    }
    navigationController.dismiss(animated: true) {
      self.delegate?.addNewWalletCoordinator(didAdd: wallet, chain: KNGeneralProvider.shared.currentChain)
    }
  }
}

extension KNAddNewWalletCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.addNewWalletCoordinatorDidSendRefCode(code)
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
    delegate?.addNewWalletCoordinator(didAdd: watchAddress, chain: chain)
  }
  
  func importWalletCoordinatorDidImport(wallet: KWallet, chain: ChainType) {
    didImportWallet(wallet: wallet, chain: chain)
  }
  
  func importWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.addNewWalletCoordinatorDidSendRefCode(code)
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
      self.createWatchWallet()
    case .close:
      self.navigationController.dismiss(animated: false) {
        DispatchQueue.main.async {
          if AppDelegate.shared.coordinator.tabbarController != nil {
            AppDelegate.shared.coordinator.tabbarController.tabBar.isHidden = false
          }
        }
      }
    }
  }
}

extension KNAddNewWalletCoordinator: AddWatchWalletViewControllerDelegate {
  func addWatchWalletViewControllerDidEdit(_ controller: AddWatchWalletViewController, address: KAddress, addressString: String, name: String?) {
    if address.addressString == addressString {
      var address = address
      address.addressString = addressString
      address.name = name.whenNilOrEmpty(Strings.imported)
      
      try? WalletManager.shared.updateWatchAddress(address: address)
      
      if let contact = KNContactStorage.shared.get(forPrimaryKey: addressString) {
        let newContact = contact.clone()
        newContact.name = name.whenNilOrEmpty(Strings.imported)
        KNContactStorage.shared.update(contacts: [newContact])
        self.navigationController.showSuccessTopBannerMessage(
          with: "",
          message: Strings.editWalletSuccess,
          time: 1
        )
      }
      delegate?.addNewWalletCoordinator(didAdd: address, chain: KNGeneralProvider.shared.currentChain)
      self.navigationController.dismiss(animated: true, completion: nil)
    } else {
      try? WalletManager.shared.removeAddress(address: address)
      self.importNewWatchWallet(address: addressString, name: name, isAdd: false)
    }
  }
  
  func addWatchWalletViewController(_ controller: AddWatchWalletViewController, didAddAddress address: String, name: String?) {
    self.importNewWatchWallet(address: address, name: name)
  }

  func addWatchWalletViewControllerDidClose(_ controller: AddWatchWalletViewController) {
    self.navigationController.dismiss(animated: true, completion: nil)
  }

  fileprivate func importNewWatchWallet(address: String, name: String?, isAdd: Bool = true) {
    let currentChain = KNGeneralProvider.shared.currentChain
    do {
      let watchAddress = try WalletManager.shared.addWatchWallet(address: address, addressType: currentChain.addressType, name: name.whenNilOrEmpty(Strings.imported))
      if isAdd {
        self.navigationController.showSuccessTopBannerMessage(
          with: Strings.walletImported,
          message: Strings.importWalletSuccess,
          time: 1
        )
      } else {
        self.navigationController.showSuccessTopBannerMessage(
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
      delegate?.addNewWalletCoordinator(didAdd: watchAddress, chain: currentChain)
      self.navigationController.dismiss(animated: true, completion: nil)
    } catch {
      guard let error = error as? WalletManagerError else {
        self.navigationController.showErrorTopBannerMessage(message: error.localizedDescription)
        return
      }
      switch error {
      case .duplicatedWallet:
        self.navigationController.showErrorTopBannerMessage(message: Strings.addressExisted)
      default:
        self.navigationController.showErrorTopBannerMessage(message: error.localizedDescription)
      }
      self.navigationController.dismiss(animated: true, completion: nil)
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
