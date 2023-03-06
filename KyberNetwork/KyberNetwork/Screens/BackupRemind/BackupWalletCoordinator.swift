//
//  BackupWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/03/2023.
//

import Foundation
import BaseModule
import UIKit
import KrystalWallets

class BackUpWalletCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    let parentNav: UINavigationController
    let walletID: String
    var onBackupFinish: (() -> ())?
    var navigationController: UINavigationController!
    var passcodeCoordinator: KNPasscodeCoordinator?
    
    init(parentNav: UINavigationController, walletID: String) {
        self.parentNav = parentNav
        self.walletID = walletID
    }
    
    func start() {
        showPasscode()
    }
    
    func showPasscode() {
        self.passcodeCoordinator = KNPasscodeCoordinator(navigationController: parentNav, type: .verifyPasscode)
        self.passcodeCoordinator?.delegate = self
        self.passcodeCoordinator?.start()
    }
    
    func openBackupWallet() {
        do {
            let mnemonic = try WalletManager.shared.exportMnemonic(walletID: walletID)
            let seeds = mnemonic.split(separator: " ").map({ return String($0) })
            let viewModel = BackUpWalletViewModel(seeds: seeds, walletId: walletID)
            let backUpVC = BackUpWalletViewController(viewModel: viewModel)
            backUpVC.delegate = self
            navigationController = UINavigationController(rootViewController: backUpVC)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.setNavigationBarHidden(true, animated: false)
            parentNav.present(navigationController, animated: true)
        } catch {
            print("Cannot export mnemonic")
        }
    }
    
}

extension BackUpWalletCoordinator: BackUpWalletViewControllerDelegate {
    func didFinishBackup(_ controller: BackUpWalletViewController) {
        navigationController.dismiss(animated: true) {
            self.onBackupFinish?()
        }
    }
}

extension BackUpWalletCoordinator: KNPasscodeCoordinatorDelegate {
    func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
        self.passcodeCoordinator?.stop {}
    }
    
    func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
        self.passcodeCoordinator?.stop {
            self.openBackupWallet()
        }
    }
    
    func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
        self.passcodeCoordinator?.stop {}
    }
}
