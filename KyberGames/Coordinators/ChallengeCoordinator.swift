//
//  ChallengeCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit

class ChallengeCoordinator: BaseCoordinator {
  
  var navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  override func start() {
    let vc = ChallengeViewController.instantiateFromNib()
    let viewModel = ChallengeViewModel()
    
    viewModel.onTapBack = { [weak self] in
      self?.navigationController.popViewController(animated: true)
      self?.onCompleted?()
    }
    
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = true
    navigationController.pushViewController(vc, animated: true)
  }
  
}
