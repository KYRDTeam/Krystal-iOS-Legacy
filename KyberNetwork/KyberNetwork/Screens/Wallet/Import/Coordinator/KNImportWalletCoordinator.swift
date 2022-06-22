// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import TrustKeystore
import KrystalWallets

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: KWallet, chain: ChainType)
  func importWalletCoordinatorDidImport(watchAddress: KAddress, chain: ChainType)
  func importWalletCoordinatorDidClose()
  func importWalletCoordinatorDidSendRefCode(_ code: String)
}

class KNImportWalletCoordinator: Coordinator {
  
  weak var delegate: KNImportWalletCoordinatorDelegate?
  let navigationController: UINavigationController
  var keystore: Keystore!
  var coordinators: [Coordinator] = []
  var refCode: String = ""
  let walletManager = WalletManager.shared
  
  init(
    navigationController: UINavigationController
//    keystore: Keystore
  ) {
    self.navigationController = navigationController
//    self.keystore = keystore
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
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: ["action": "name_empty"])
    } else {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: ["action": "name_not_empty"])
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
        KNCrashlyticsUtil.logCustomEvent(withName: "iw_pk_success", customAttributes: nil)
        onImportWalletSuccess(wallet: wallet, chain: selectedChain)
      } catch {
        navigationController.topViewController?.displayAlert(message: importErrorMessage(error: error))
        KNCrashlyticsUtil.logCustomEvent(withName: "iw_pk_fail", customAttributes: nil)
      }
    case .mnemonic(let words, _):
      do {
        let wallet = try walletManager.import(mnemonic: words.joined(separator: " "), name: name.whenNilOrEmpty("Imported"))
        KNCrashlyticsUtil.logCustomEvent(withName: "iw_seed_success", customAttributes: nil)
        onImportWalletSuccess(wallet: wallet, chain: selectedChain)
      } catch {
        navigationController.topViewController?.displayAlert(message: importErrorMessage(error: error))
        KNCrashlyticsUtil.logCustomEvent(withName: "iw_seed_fail", customAttributes: nil)
      }
    case .keystore(let key, let password):
      do {
        let wallet = try walletManager.import(keystore: key, addressType: addressType, password: password, name: name.whenNilOrEmpty("Imported"))
        KNCrashlyticsUtil.logCustomEvent(withName: "iw_json_success", customAttributes: nil)
        onImportWalletSuccess(wallet: wallet, chain: selectedChain)
      } catch {
        navigationController.topViewController?.displayAlert(message: importErrorMessage(error: error))
        KNCrashlyticsUtil.logCustomEvent(withName: "iw_json_fail", customAttributes: nil)
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
  
  func sendRefCode(_ code: String, account: Account) {
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    // TODO: TUNG - Sign message
    let result = self.keystore.signMessage(sendData, for: account)
    switch result {
    case .success(let signedData):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.registerReferrer(address: account.address.description, referralCode: code, signature: signedData.hexEncoded)) { (result) in
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
    case .failure(let error):
      print("[Send ref code] \(error.localizedDescription)")
    }
  }
  
  private func onImportWalletSuccess(wallet: KWallet, chain: ChainType) {
    showImportSuccessMessage()
    addToContacts(wallet: wallet)
    sendRefCode(refCode: refCode, wallet: wallet)
    delegate?.importWalletCoordinatorDidImport(wallet: wallet, chain: chain)
  }
  
  private func showImportSuccessMessage() {
    self.navigationController.showSuccessTopBannerMessage(
      with: Strings.walletImported,
      message: Strings.importWalletSuccess,
      time: 1
    )
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
  
  private func sendRefCode(refCode: String, wallet: KWallet) {
    guard !refCode.isEmpty else { return }
    
    // TODO: - Tung -
    print("Send ref code here")
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
