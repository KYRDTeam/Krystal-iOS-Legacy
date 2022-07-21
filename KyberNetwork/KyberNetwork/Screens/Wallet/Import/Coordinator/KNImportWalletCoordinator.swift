// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import TrustCore
import TrustKeystore

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?, importType: ImportType, importMethod: StorageType, selectedChain: ChainType, importChainType: ImportWalletChainType)
  func importWalletCoordinatorDidClose()
  func importWalletCoordinatorDidSendRefCode(_ code: String)
}

class KNImportWalletCoordinator: Coordinator {

  weak var delegate: KNImportWalletCoordinatorDelegate?
  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []
  var refCode: String = ""

  init(
    navigationController: UINavigationController,
    keystore: Keystore
  ) {
    self.navigationController = navigationController
    self.keystore = keystore
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
    self.navigationController.topViewController?.displayLoading(text: "\(NSLocalizedString("importing.wallet", value: "Importing wallet", comment: ""))...", animated: true)
    if name == nil || name?.isEmpty == true {
      Tracker.track(event: .screenImportWallet, customAttributes: ["action": "name_empty"])
    } else {
      Tracker.track(event: .screenImportWallet, customAttributes: ["action": "name_not_empty"])
    }
    self.keystore.importWallet(type: type, importType: importType) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      switch result {
      case .success(let wallet):
        self.navigationController.showSuccessTopBannerMessage(
          with: NSLocalizedString("wallet.imported", value: "Wallet Imported", comment: ""),
          message: NSLocalizedString("you.have.successfully.imported.a.wallet", value: "You have successfully imported a wallet", comment: ""),
          time: 1
        )
        let walletName: String = {
          if name == nil || name?.isEmpty == true { return "Imported" }
          return name ?? "Imported"
        }()

        self.delegate?.importWalletCoordinatorDidImport(wallet: wallet, name: walletName, importType: type, importMethod: type.toStorageType(), selectedChain: selectedChain, importChainType: type.toStorageType() == .seeds ? .multiChain : importType)
        
        //TODO: add solana sign message
        if !self.refCode.isEmpty {
          if case .real(let account) = wallet.type {
            self.sendRefCode(self.refCode, account: account)
          }
        }
        switch type {
        case .keystore:
          Tracker.track(event: .iwJSONSuccess)
        case .privateKey:
          Tracker.track(event: .iwPKSuccess)
        case .mnemonic:
          Tracker.track(event: .iwSeedSuccess)
        case .watch:
          break
        }
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
        switch type {
        case .keystore:
          Tracker.track(event: .iwJSONFail)
        case .privateKey:
          Tracker.track(event: .iwPKFail)
        case .mnemonic:
          Tracker.track(event: .iwSeedFail)
        case .watch:
          break
        }
      }
    }
  }

  func sendRefCode(_ code: String, account: Account) {
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    let result = self.keystore.signMessage(sendData, for: account)
    switch result {
    case .success(let signedData):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.requestWithFilter(.registerReferrer(address: account.address.description, referralCode: code, signature: signedData.hexEncoded)) { (result) in
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
}
