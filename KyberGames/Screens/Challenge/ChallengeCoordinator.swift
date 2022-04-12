//
//  ChallengeCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit

class ChallengeCoordinator: Coordinator {
  
  var parentCoordinator: Coordinator?
  var children: [Coordinator] = []
  var navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  func start() {
    let vc = ChallengeViewController.instantiateFromNib()
    let viewModel = ChallengeViewModel()
    
    viewModel.onTapBack = { [navigationController] in
      navigationController.popViewController(animated: true)
    }
    
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = true
    navigationController.pushViewController(vc, animated: true)
  }
  
}
