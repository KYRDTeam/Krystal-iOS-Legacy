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
    let vm = PromoCodeListViewModel()
    let controller = PromoCodeListViewController(viewModel: vm)
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
    let todayTS = Date().timeIntervalSince1970
    let item1 = PromoCodeItem(title: "$5 GIVEAWAY for new users on Avalanche ..... long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn long logn logn logn logn ", expired: todayTS + 100, description: "", logoURL: "", bannerURL: "", type: .pending)
    let item2 = PromoCodeItem(title: "$1500 GIVEAWAY for new users on Avalanche ..... long logn logn logn logn ", expired: todayTS + 100, description: "", logoURL: "", bannerURL: "", type: .expired)
    
    let item3 = PromoCodeItem(title: "$1500 GIVEAWAY for new users on Avalanche ..... long logn logn logn logn ", expired: todayTS + 100, description: "", logoURL: "", bannerURL: "", type: .claimed)
    
    let items = [item1, item2, item3]
    self.rootViewController.coordinatorDidUpdatePromoCodeItems(items)
  }
  
  func stop() {
    
  }
}
