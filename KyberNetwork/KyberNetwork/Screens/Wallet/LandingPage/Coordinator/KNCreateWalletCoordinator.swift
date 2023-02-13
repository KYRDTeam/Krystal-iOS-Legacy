// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import QRCodeReaderViewController
import Moya
import KrystalWallets

protocol KNCreateWalletCoordinatorDelegate: class {
  func createWalletCoordinatorDidCreateWallet(coordinator: KNCreateWalletCoordinator, _ wallet: KWallet?, name: String?, chain: ChainType)
  func createWalletCoordinatorDidClose(coordinator: KNCreateWalletCoordinator)
}

class KNCreateWalletCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []

  fileprivate var newWallet: KWallet?
  fileprivate var name: String?
  fileprivate var refCode: String = ""
  weak var delegate: KNCreateWalletCoordinatorDelegate?
  var createWalletController: CreateWalletViewController?
  var targetChain: ChainType
  var finishWalletController: FinishCreateWalletViewController?
  var backupViewController: BackUpWalletViewController?
  
  let walletManager = WalletManager.shared

  fileprivate var isCreating: Bool = false

  init(
    navigationController: UINavigationController,
    newWallet: KWallet?,
    name: String?,
    targetChain: ChainType = KNGeneralProvider.shared.currentChain
  ) {
    self.navigationController = navigationController
    self.newWallet = newWallet
    self.name = name
    self.targetChain = targetChain
  }

  func start() {
    if let wallet = self.newWallet {
      self.isCreating = false
      self.openBackUpWallet(wallet, name: self.name)
    } else {
      self.isCreating = true
      let createWalletVC = CreateWalletViewController()
      createWalletVC.hidesBottomBarWhenPushed = true
      createWalletVC.delegate = self
      self.navigationController.pushViewController(createWalletVC, animated: true)
      self.createWalletController = createWalletVC
    }
  }

  func updateNewWallet(_ wallet: KWallet?, name: String?) {
    self.newWallet = wallet
    self.name = name
  }
  
  fileprivate func showCreateWalletSuccess(_ wallet: KWallet) {
    self.newWallet = wallet
    let viewModel = FinishCreateWalletViewModel(wallet: wallet)
    let finishVC = FinishCreateWalletViewController(viewModel: viewModel)
    finishVC.delegate = self
    self.finishWalletController = finishVC
    self.navigationController.show(finishVC, sender: nil)
  }

  /**
   Open back up wallet view for new wallet created from the app
   Always using 12 words seeds to back up the wallet
   */
  fileprivate func openBackUpWallet(_ wallet: KWallet, name: String?) {
    self.newWallet = wallet
    self.name = name

    do {
      let mnemonic = try walletManager.exportMnemonic(walletID: wallet.id)
      let seeds = mnemonic.split(separator: " ").map({ return String($0) })
      let viewModel = BackUpWalletViewModel(seeds: seeds, walletId: wallet.id)
      let backUpVC = BackUpWalletViewController(viewModel: viewModel)
      backUpVC.delegate = self
      backupViewController = backUpVC
      self.navigationController.pushViewController(backUpVC, animated: true)
    } catch {
      self.delegate?.createWalletCoordinatorDidCreateWallet(coordinator: self, self.newWallet, name: name, chain: self.targetChain)
      print("Can not get seeds from account")
    }
  }
  
  func sendRefCode(_ code: String, wallet: KWallet) {
    guard let address = WalletManager.shared.address(forWalletID: wallet.id) else {
      return
    }
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    do {
      let signedData = try SignerFactory().getSigner(address: address).signMessageHash(address: address, data: sendData, addPrefix: false)
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
      provider.requestWithFilter(.registerReferrer(address: address.addressString, referralCode: code, signature: signedData.hexEncoded)) { (result) in
        if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let isSuccess = json["success"] as? Bool, isSuccess {
            self.navigationController.showTopBannerView(message: "Success register referral code")
          } else if let error = json["error"] as? String {
            self.navigationController.showTopBannerView(message: error)
          } else {
            self.navigationController.showTopBannerView(message: "Fail to register referral code")
          }
        } else {
            self.navigationController.showTopBannerView(message: "Fail to register referral code")
        }
      }
    } catch {
        self.navigationController.showTopBannerView(message: "Fail to register referral code")
    }
  }
}

extension KNCreateWalletCoordinator: BackUpWalletViewControllerDelegate {
  func didFinishBackup(_ controller: BackUpWalletViewController) {
    guard let wallet = self.newWallet else { return }
    backupViewController = nil
    self.delegate?.createWalletCoordinatorDidCreateWallet(coordinator: self, wallet, name: self.name, chain: targetChain)
  }
}

extension KNCreateWalletCoordinator: CreateWalletViewControllerDelegate {
  func createWalletViewController(_ controller: CreateWalletViewController, run event: CreateWalletViewControllerEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true) {
        self.delegate?.createWalletCoordinatorDidClose(coordinator: self)
      }
    case .next(let name):
      self.navigationController.displayLoading(text: Strings.creating, animated: true)
      do {
        let wallet = try self.walletManager.createWallet(name: name)
        DispatchQueue.main.async {
          self.navigationController.hideLoading()
          self.name = name
          self.showCreateWalletSuccess(wallet)
          if !self.refCode.isEmpty {
            self.sendRefCode(self.refCode.uppercased(), wallet: wallet)
          }
        }
      } catch {
        return
      }
    case .openQR:
      self.openQRCode(controller)
    case .sendRefCode(code: let code):
      self.refCode = code
    }
  }

  fileprivate func openQRCode(_ controller: UIViewController) {
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = self
    controller.present(qrcode, animated: true, completion: nil)
  }
}

extension KNCreateWalletCoordinator: FinishCreateWalletViewControllerDelegate {
  func finishCreateWalletViewController(_ controller: FinishCreateWalletViewController, run event: FinishCreateWalletViewControllerEvent) {
    switch event {
    case .continueUseApp:
      guard let wallet = self.newWallet else { return }
      self.finishWalletController = nil
      self.delegate?.createWalletCoordinatorDidCreateWallet(coordinator: self, wallet, name: self.name, chain: targetChain)
    case .backup:
      guard let wallet = self.newWallet else { return }
      self.openBackUpWallet(wallet, name: self.name)
    }
  }
}

extension KNCreateWalletCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.createWalletController?.containerViewDidUpdateRefCode(result)
    }
  }
}
