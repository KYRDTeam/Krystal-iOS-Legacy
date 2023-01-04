// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import TrustKeystore
import KrystalWallets
import Utilities
import AppState

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: KWallet, chain: ChainType)
  func importWalletCoordinatorDidImport(watchAddress: KAddress, chain: ChainType)
  func importWalletCoordinatorDidClose()
}

class KNImportWalletCoordinator: Coordinator {
  
  weak var delegate: KNImportWalletCoordinatorDelegate?
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var refCode: String = ""
  let walletManager = WalletManager.shared
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  func startImportFlow(privateKey: String, chain: ChainType) {
    let importType: ImportWalletChainType = chain.isEVM ? .evm : .solana
    let vc = KNImportWalletViewController.instantiateFromNib()
    vc.importType = importType
    vc.selectedChainType = chain
    vc.currentImportWalletType = .privateKey
    vc.privateKey = privateKey
    vc.delegate = self
    self.navigationController.pushViewController(vc, animated: true)
  }
  
  func start() {
    let selectChainVC = SelectChainViewController()
    selectChainVC.delegate = self
    self.navigationController.pushViewController(selectChainVC, animated: true)
  }
  
  func stop(completion: (() -> Void)? = nil) {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.importWalletCoordinatorDidClose()
      completion?()
    }
  }
}

extension KNImportWalletCoordinator: SelectChainDelegate {
  func selectChainViewController(_ controller: SelectChainViewController, run event: SelectChainEvent) {
    let importVC: KNImportWalletViewController = {
      let controller = KNImportWalletViewController()
      controller.delegate = self
      controller.loadViewIfNeeded()
      return controller
    }()
    switch event {
    case .back:
      self.stop()
      return
    case .importMultiChain:
      importVC.importType = .multiChain
        importVC.selectedChainType = .all
    case .importEVM(let type):
      importVC.importType = .evm
      importVC.selectedChainType = type
    case .importSolana:
      importVC.importType = .solana
      importVC.selectedChainType = .solana
    }
    self.navigationController.pushViewController(importVC, animated: true)
  }
}

extension KNImportWalletCoordinator: KNImportWalletViewControllerDelegate {
  func importWalletViewController(_ controller: KNImportWalletViewController, run event: KNImportWalletViewEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true)
    case .importJSON(let json, let password, let name, let importType, let currentChain):
      self.importWallet(with: .keystore(string: json, password: password), name: name, importType: importType, selectedChain: currentChain)
    case .importPrivateKey(let privateKey, let name, let importType, let currentChain):
      self.importWallet(with: .privateKey(privateKey: privateKey), name: name, importType: importType, selectedChain: currentChain)
    case .importSeeds(let seeds, let name, let importType, let currentChain):
      self.importWallet(with: .mnemonic(words: seeds, password: ""), name: name, importType: importType, selectedChain: currentChain)
    case .sendRefCode(code: let code):
      self.refCode = code
    }
  }
  
  fileprivate func importWallet(with type: ImportType, name: String?, importType: ImportWalletChainType, selectedChain: ChainType) {
    if name == nil || name?.isEmpty == true {
      Tracker.track(event: .screenImportWallet, customAttributes: ["action": "name_empty"])
    } else {
      Tracker.track(event: .screenImportWallet, customAttributes: ["action": "name_not_empty"])
    }
    
    let addressType: KAddressType = {
      switch importType {
      case .multiChain, .evm:
        return .evm
      case .solana:
        return .solana
      }
    }()
    
    switch type {
    case .privateKey(let privateKey):
      do {
        let wallet = try walletManager.import(privateKey: privateKey, addressType: addressType, name: name.whenNilOrEmpty("Imported"))
        AppState.shared.markWalletBackedUp(walletID: wallet.id)
        Tracker.track(event: .iwPKSuccess)
        onImportWalletSuccess(wallet: wallet, chain: selectedChain)
      } catch {
        navigationController.topViewController?.displayAlert(message: importErrorMessage(error: error))
        Tracker.track(event: .iwPKFail)
      }
    case .mnemonic(let words, _):
      do {
        let wallet = try walletManager.import(mnemonic: words.joined(separator: " "), name: name.whenNilOrEmpty("Imported"))
        AppState.shared.markWalletBackedUp(walletID: wallet.id)
        Tracker.track(event: .iwSeedSuccess)
        onImportWalletSuccess(wallet: wallet, chain: selectedChain)
      } catch {
        navigationController.topViewController?.displayAlert(message: importErrorMessage(error: error))
        Tracker.track(event: .iwSeedFail)
      }
    case .keystore(let key, let password):
      do {
        let wallet = try walletManager.import(keystore: key, addressType: addressType, password: password, name: name.whenNilOrEmpty("Imported"))
        AppState.shared.markWalletBackedUp(walletID: wallet.id)
        Tracker.track(event: .iwJSONSuccess)
        onImportWalletSuccess(wallet: wallet, chain: selectedChain)
      } catch {
        navigationController.topViewController?.displayAlert(message: importErrorMessage(error: error))
        Tracker.track(event: .iwJSONFail)
      }

    case .watch(let address, _):
      do {
        let importAddress = try walletManager.addWatchWallet(address: address, addressType: addressType, name: name.whenNilOrEmpty("Imported"))
        delegate?.importWalletCoordinatorDidImport(watchAddress: importAddress, chain: selectedChain)
      } catch {
        return
      }
    }
  }
  
  func sendRefCode(_ code: String, wallet: KWallet) {
    guard let address = WalletManager.shared.address(forWalletID: wallet.id) else {
      return
    }
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    let signer = SignerFactory().getSigner(address: address)
    do {
      let signedData = try signer.signMessageHash(address: address, data: sendData, addPrefix: false)
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.requestWithFilter(.registerReferrer(address: address.addressString, referralCode: code, signature: signedData.hexEncoded)) { (result) in
        if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let isSuccess = json["success"] as? Bool, isSuccess {
            self.navigationController.showTopBannerView(message: "Success register referral code")
          } else if let error = json["error"] as? String {
            self.navigationController.showTopBannerView(message: error)
          } else {
            self.navigationController.showTopBannerView(message: "Fail to register referral code")
          }
        }
      }
    } catch {
      print("[Send ref code] \(error.localizedDescription)")
    }
  }
    
  private func onImportWalletSuccess(wallet: KWallet, chain: ChainType) {
    showImportSuccessMessage()
    addToContacts(wallet: wallet)
    sendRefCode(refCode, wallet: wallet)
    delegate?.importWalletCoordinatorDidImport(wallet: wallet, chain: chain)
  }
  
  private func showImportSuccessMessage() {
    self.navigationController.showSuccessTopBannerMessage(
      with: Strings.walletImported,
      message: Strings.importWalletSuccess,
      time: 1
    )
    MixPanelManager.track("import_done_pop_up_open", properties: ["screenid": "import_done_pop_up"])
  }
  
  private func addToContacts(wallet: KWallet) {
    let addresses = walletManager.getAllAddresses(walletID: wallet.id)
    
    let contacts: [KNContact] = addresses.map { address in
      return KNContact(address: address.addressString,
                       name: wallet.name,
                       chainType: address.addressType.importChainType.rawValue)
    }
    
    KNContactStorage.shared.update(contacts: contacts)
  }
}

extension KNImportWalletCoordinator {
  
  func importErrorMessage(error: Error) -> String {
    if let error = error as? WalletManagerError {
      switch error {
      case .invalidJSON:
        return Strings.failedToParseJSON
      case .duplicatedWallet:
        return Strings.alreadyAddedWalletAddress
      case .cannotCreateWallet:
        return Strings.failedToCreateWallet
      case .cannotImportWallet:
        return Strings.failedToImportWallet
      default:
        return Strings.failedToImportWallet
      }
    } else {
      return Strings.failedToImportWallet
    }
  }
  
}
