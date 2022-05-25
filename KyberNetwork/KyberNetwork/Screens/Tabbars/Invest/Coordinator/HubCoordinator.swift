//
//  HubCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 23/05/2022.
//

import UIKit

protocol HubCoordinatorDelegate: class {
  func dAppCoordinatorDidSelectAddWallet()
  func dAppCoordinatorDidSelectWallet(_ wallet: Wallet)
  func dAppCoordinatorDidSelectManageWallet()
  func dAppCoordinatorDidSelectAddChainWallet(chainType: ChainType)
}

class HubCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  weak var delegate: HubCoordinatorDelegate?
  lazy var rootViewController: HubViewController = {
    let controller = HubViewController(session: self.session)
    controller.delegate = self
    return controller
  }()

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func stop() {
    
  }

}

extension HubCoordinator: HubViewControllerDelegate {
  func dAppCoordinatorDidSelectAddWallet() {
    self.delegate?.dAppCoordinatorDidSelectAddWallet()
  }
  
  func dAppCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.dAppCoordinatorDidSelectWallet(wallet)
  }
  
  func dAppCoordinatorDidSelectManageWallet() {
    self.delegate?.dAppCoordinatorDidSelectManageWallet()
  }
  
  func dAppCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.dAppCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
}
