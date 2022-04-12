//
//  GameListCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class GameListCoordinator: Coordinator {
  var parentCoordinator: Coordinator?
  var children: [Coordinator] = []
  var navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  func start() {
    let vc = GameListViewController.instantiateFromNib()
    let viewModel = GameListViewModel()
    
    viewModel.onTapBack = { [navigationController] in
      navigationController.popViewController(animated: true)
    }
    
    viewModel.onNotificationTap = { isNotiOn in
      self.openTurnOnNotiPopup(viewController: vc)
    }
    
    viewModel.onCheckinTap = {
      self.openCheckinRewardPopup(viewController: vc)
    }
    
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = true
    navigationController.pushViewController(vc, animated: true)
  }
  
  func openTurnOnNotiPopup(viewController: UIViewController) {
    AlertPopupCoordinator(parentViewController: viewController).start()
  }
  
  func openCheckinRewardPopup(viewController: UIViewController) {
    CheckinRewardPopupCoordinator(parentViewController: viewController).start()
  }
  
}
