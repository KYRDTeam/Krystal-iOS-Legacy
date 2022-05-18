//
//  BridgeCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class BridgeCoordinator: Coordinator {
  fileprivate var session: KNSession
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  
  lazy var rootViewController: BridgeViewController = {
    let controller = BridgeViewController()
    controller.delegate = self
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
  }
  

}

extension BridgeCoordinator: BridgeViewControllerDelegate {
  func bridgeViewControllerController(_ controller: BridgeViewController, run event: BridgeEvent) {
    
  }
}
