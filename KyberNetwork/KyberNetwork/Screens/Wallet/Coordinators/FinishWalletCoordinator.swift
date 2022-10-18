//
//  FinishWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 06/10/2022.
//

import Foundation
import UIKit
import KrystalWallets

class FinishWalletCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  let wallet: KWallet
  let rootViewController: FinishCreateWalletViewController
  
  init(navigationController: UINavigationController, wallet: KWallet) {
    let viewModel = FinishCreateWalletViewModel(wallet: wallet)
    self.rootViewController = FinishCreateWalletViewController(viewModel: viewModel)
    self.navigationController = navigationController
    self.wallet = wallet
    self.rootViewController.delegate = self
  }
  
  func start() {
    self.navigationController.show(rootViewController, sender: nil)
  }
}

extension FinishWalletCoordinator: FinishCreateWalletViewControllerDelegate {
  
  func finishCreateWalletViewController(_ controller: FinishCreateWalletViewController, run event: FinishCreateWalletViewControllerEvent) {
    switch event {
    case .continueUseApp:
      ()
    case .backup:
      ()
    }
  }
  
}
