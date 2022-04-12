//
//  GameListCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class GameListCoordinator: BaseCoordinator {
  var navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  override func start() {
    let vc = GameListViewController.instantiateFromNib()
    let viewModel = GameListViewModel()
    
    viewModel.onTapBack = { [weak self] in
      self?.navigationController.popViewController(animated: true)
      self?.onCompleted?()
    }
    
    viewModel.onNotificationTap = { [weak self] isNotiOn in
      self?.openTurnOnNotiPopup(viewController: vc)
    }
    
    viewModel.onCheckinTap = { [weak self] in
      self?.openCheckinRewardPopup(viewController: vc)
    }
    
    viewModel.onSelectGame = { [weak self] game in
      switch game.id {
      case "0":
        self?.openLuckySpin()
      default:
        self?.openChallenge()
      }
    }
    
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = true
    
    navigationController.pushViewController(vc, animated: true)
  }
  
  func openTurnOnNotiPopup(viewController: UIViewController) {
    let coordinator = AlertPopupCoordinator(parentViewController: viewController)
    coordinate(coordinator: coordinator)
  }
  
  func openCheckinRewardPopup(viewController: UIViewController) {
    let coordinator = CheckinRewardPopupCoordinator(parentViewController: viewController)
    coordinate(coordinator: coordinator)
  }
  
  func openLuckySpin() {
    let coordinator = LuckySpinCoordinator(navigationController: navigationController)
    coordinate(coordinator: coordinator)
  }
  
  func openChallenge() {
    let coordinator = ChallengeCoordinator(navigationController: navigationController)
    coordinate(coordinator: coordinator)
  }
  
}
