//
//  RewardHuntingCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import UIKit

class RewardHuntingCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  let url: URL
  
  init(navigationController: UINavigationController, url: URL) {
    self.navigationController = navigationController
    self.url = url
  }
  
  func start() {
    let vc = RewardHuntingViewController()
    let viewModel = RewardHuntingViewModel(url: url)
    viewModel.actions = RewardHuntingViewModelActions(goBack: goBack)
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = true
    navigationController.pushViewController(vc, animated: true)
  }
  
  private func goBack() {
    navigationController.popViewController(animated: true, completion: nil)
  }
  
}

