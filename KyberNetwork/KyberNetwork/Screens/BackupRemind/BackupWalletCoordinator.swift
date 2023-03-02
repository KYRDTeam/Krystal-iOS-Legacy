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
    let parentViewController: UIViewController
    let walletID: String
    var onBackupFinish: (() -> ())?
    
    init(parentViewController: UIViewController, walletID: String) {
        self.parentViewController = parentViewController
        self.walletID = walletID
    }
    
    func start() {
        do {
            let mnemonic = try WalletManager.shared.exportMnemonic(walletID: walletID)
            let seeds = mnemonic.split(separator: " ").map({ return String($0) })
            let viewModel = BackUpWalletViewModel(seeds: seeds, walletId: walletID)
            let backUpVC = BackUpWalletViewController(viewModel: viewModel)
            backUpVC.delegate = self
            let navigation = UINavigationController(rootViewController: backUpVC)
            navigation.modalPresentationStyle = .fullScreen
            navigation.setNavigationBarHidden(true, animated: false)
            parentViewController.present(navigation, animated: true)
        } catch {
            print("Cannot export mnemonic")
        }
    }
    
}

extension BackUpWalletCoordinator: BackUpWalletViewControllerDelegate {
    func didFinishBackup(_ controller: BackUpWalletViewController) {
        onBackupFinish?()
    }
}
