//
//  LuckySpinCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import Foundation
import UIKit

class LuckySpinCoordinator: Coordinator {
  var parentCoordinator: Coordinator?
  var children: [Coordinator] = []
  var navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  func start() {
    let vc = LuckySpinViewController.instantiateFromNib()
    let viewModel = LuckySpinViewModel()
    
    viewModel.onTapBack = { [navigationController] in
      navigationController.popViewController(animated: true)
    }
    
    viewModel.onTapAddTurns = { [navigationController] in
      ChallengeTasksCoordinator(navigationController: navigationController).start()
    }
    
    vc.viewModel = viewModel
    navigationController.pushViewController(vc, animated: true)
  }
  
}
