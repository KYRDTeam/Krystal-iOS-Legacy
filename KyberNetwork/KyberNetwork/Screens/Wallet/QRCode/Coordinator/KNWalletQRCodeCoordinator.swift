// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD
import KrystalWallets
import BaseModule

class KNWalletQRCodeCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  lazy var viewModel: KNWalletQRCodeViewModel = {
    return KNWalletQRCodeViewModel()
  }()

  lazy var rootViewController: KNWalletQRCodeViewController = {
    let controller = KNWalletQRCodeViewController(viewModel: self.viewModel)
    controller.loadViewIfNeeded()
    return controller
  }()

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }
}
