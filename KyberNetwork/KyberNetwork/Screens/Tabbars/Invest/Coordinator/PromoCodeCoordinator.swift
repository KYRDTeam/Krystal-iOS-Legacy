//
//  PromoCodeCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/03/2022.
//

import Foundation

class PromoCodeCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  
  lazy var rootViewController: PromoCodeListViewController = {
    let controller = PromoCodeListViewController()
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
  }
  
  func stop() {
    
  }
}
