//
//  ExportWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 05/10/2022.
//

import Foundation
import UIKit
import KrystalWallets

class ExportWalletCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  let wallet: KWallet
  let addressType: KAddressType
  
  var onCompleted: (() -> ())?
  
  init(navigationController: UINavigationController, wallet: KWallet, addressType: KAddressType) {
    self.navigationController = navigationController
    self.wallet = wallet
    self.addressType = addressType
  }
  
  func start() {
    let alertController = KNPrettyAlertController(
      title: Strings.backupWalletWarningTitle,
      isWarning: true,
      message: Strings.backupWalletWarningMessage,
      secondButtonTitle: Strings.continue,
      firstButtonTitle: Strings.cancel,
      secondButtonAction: {
        self.openAuthPasscode()
      }, firstButtonAction: {
      }
    )
    self.navigationController.present(alertController, animated: true, completion: nil)
    MixPanelManager.track("export_wallet_warning_pop_up_open", properties: ["screenid": "export_wallet_warning_pop_up"])
    
  }
  
  func openBackupActionSheet() {
    var action = [UIAlertAction]()
    
    switch wallet.importType {
    case .mnemonic:
      action.append(UIAlertAction(
        title: Strings.backupMnemonic,
        style: .default,
        handler: { _ in
          self.backupMnemonic(wallet: self.wallet)
          MixPanelManager.track("edit_wallet_export_options", properties: ["screenid": "export_wallet_pop_up", "option": "export_seeds"])
        }
      ))
    case .privateKey:
      break
    }
    if addressType.canExportKeystore {
      action.append(UIAlertAction(
        title: Strings.backupKeystore,
        style: .default,
        handler: { _ in
          self.backupKeystore(wallet: self.wallet, addressType: self.addressType)
          MixPanelManager.track("edit_wallet_export_options", properties: ["screenid": "export_wallet_pop_up", "option": "export_json"])
        }
      ))
    }
    action.append(UIAlertAction(
      title: Strings.backupPrivateKey,
      style: .default,
      handler: { _ in
        self.backupPrivateKey(wallet: self.wallet, addressType: self.addressType)
        MixPanelManager.track("edit_wallet_export_options", properties: ["screenid": "export_wallet_pop_up", "option": "export_key"])
      }
    ))
    
    guard !action.isEmpty else { return }
    
    action.append(UIAlertAction(
      title: Strings.cancel,
      style: .cancel,
      handler: nil)
    )
    
    let alertController = KNActionSheetAlertViewController(title: "", actions: action)
    self.navigationController.hideLoading()
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
    MixPanelManager.track("export_wallet_pop_up_open", properties: ["screenid": "export_wallet_pop_up"])
  }
  
  func backupKeystore(wallet: KWallet, addressType: KAddressType) {
    let createPassword = KNCreatePasswordViewController()
    createPassword.modalPresentationStyle = .overCurrentContext
    createPassword.modalTransitionStyle = .crossDissolve
    createPassword.onCancel = { }
    createPassword.onPasswordCreated = { [weak self] password in
      guard let self = self else { return }
      let manager = WalletManager.shared
      guard let address = manager.address(walletID: wallet.id, addressType: addressType) else {
        return
      }
      do {
        let key = try manager.exportKeystore(address: address, password: password)
        self.exportDataString(key, address: address)
      } catch {
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
    self.navigationController.topViewController?.present(createPassword, animated: true, completion: nil)
    MixPanelManager.track("export_keystore_pop_up_open", properties: ["screenid": "export_keystore_pop_up"])

  }

  func backupPrivateKey(wallet: KWallet, addressType: KAddressType) {
    do {
      let privateKey = try WalletManager.shared.exportPrivateKey(walletID: wallet.id, addressType: addressType)
      MixPanelManager.track("export_private_key_open", properties: ["screenid": "export_private_key"])
      self.openShowBackUpView(data: privateKey, wallet: wallet)
    } catch {
      self.navigationController.topViewController?.displayError(error: error)
    }
  }

  func backupMnemonic(wallet: KWallet) {
    do {
      let mnemonic = try WalletManager.shared.exportMnemonic(walletID: wallet.id)
      self.openShowBackUpView(data: mnemonic, wallet: wallet)
      MixPanelManager.track("export_mnemonic_open", properties: ["screenid": "export_mnemonic"])
    } catch {
      self.navigationController.topViewController?.displayError(error: error)
    }
  }

  func openShowBackUpView(data: String, wallet: KWallet) {
    guard let address = WalletManager.shared.getAllAddresses(walletID: wallet.id).first?.addressString else {
      return
    }
    let showBackUpVC = KNShowBackUpDataViewController(
      address: address,
      backupData: data
    )
    showBackUpVC.loadViewIfNeeded()
    self.navigationController.pushViewController(showBackUpVC, animated: true)
  }
  
  func exportDataString(_ value: String, address: KAddress) {
    let fileName = "krystal_backup_\(address.addressString)_\(DateFormatterUtil.shared.backupDateFormatter.string(from: Date())).json"
    let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
    do {
      try value.data(using: .utf8)!.write(to: url)
    } catch { return }

    let activityViewController = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    activityViewController.completionWithItemsHandler = { _, result, _, error in
      do { try FileManager.default.removeItem(at: url)
      } catch { }
    }
    activityViewController.popoverPresentationController?.sourceView = navigationController.view
    activityViewController.popoverPresentationController?.sourceRect = navigationController.view.centerRect
    self.navigationController.topViewController?.present(activityViewController, animated: true, completion: nil)
  }
  
  func openAuthPasscode() {
    let passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
    passcodeCoordinator.delegate = self
    coordinate(coordinator: passcodeCoordinator)
  }
}

extension ExportWalletCoordinator: KNPasscodeCoordinatorDelegate {
  
  func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
    coordinator.stop { [weak self] in
      self?.onCompleted?()
    }
  }
  
  func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
    coordinator.stop { [weak self] in
      self?.openBackupActionSheet()
    }
  }
  
  func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
    // Nothing to do here
  }

}
