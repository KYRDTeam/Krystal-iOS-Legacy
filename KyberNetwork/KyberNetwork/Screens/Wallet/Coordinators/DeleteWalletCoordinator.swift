//
//  DeleteWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 17/10/2022.
//

import Foundation
import KrystalWallets
import UIKit

class DeleteWalletCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    let navigationController: UINavigationController
    let wallet: KWallet
    
    var onCompleted: (() -> ())?
    
    init(navigationController: UINavigationController, wallet: KWallet) {
        self.navigationController = navigationController
        self.wallet = wallet
    }
    
    func start() {
        let alertController = KNPrettyAlertController(
            title: Strings.delete,
            message: Strings.deleteWalletConfirmMessage,
            secondButtonTitle: Strings.ok,
            firstButtonTitle: Strings.cancel,
            secondButtonAction: {
                self.openAuthPasscode()
            },
            firstButtonAction: {
                self.onCompleted?()
            }
        )
        self.navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func openAuthPasscode() {
        let passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
        passcodeCoordinator.delegate = self
        coordinate(coordinator: passcodeCoordinator)
    }
    
}

extension DeleteWalletCoordinator: KNPasscodeCoordinatorDelegate {
    
    func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
        coordinator.stop { [weak self] in
            self?.onCompleted?()
        }
    }
    
    func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
        coordinator.stop { [weak self] in
            guard let self = self else { return }
            try? WalletManager.shared.remove(wallet: self.wallet)
            self.onCompleted?()
            AppDelegate.shared.coordinator.onRemoveWallet(wallet: self.wallet)
        }
    }
    
    func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
        // Nothing to do here
    }
    
}
