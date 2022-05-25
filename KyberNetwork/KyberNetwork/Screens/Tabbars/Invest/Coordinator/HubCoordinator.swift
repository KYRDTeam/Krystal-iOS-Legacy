//
//  HubCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 23/05/2022.
//

import UIKit

class HubCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  
  lazy var rootViewController: HubViewController = {
    let controller = HubViewController(session: self.session)
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
