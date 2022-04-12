//
//  ChallengeTasksCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import Foundation
import UIKit

class ChallengeTasksCoordinator: Coordinator {
  var parentCoordinator: Coordinator?
  var children: [Coordinator] = []
  let navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  func start() {
    let vc = ChallengeTasksViewController.instantiateFromNib()
    let viewModel = ChallengeTasksViewModel()
    
    viewModel.onTapBack = {
      self.navigationController.popViewController(animated: true)
    }
    
    vc.viewModel = viewModel
    navigationController.pushViewController(vc, animated: true)
  }
  
  
}
