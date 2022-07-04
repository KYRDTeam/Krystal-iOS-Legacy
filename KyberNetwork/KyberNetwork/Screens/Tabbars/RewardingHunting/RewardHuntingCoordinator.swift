//
//  RewardHuntingCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import UIKit

protocol RewardHuntingCoordinatorDelegate: AnyObject {
  func openRewards()
}

class RewardHuntingCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  var delegate: RewardHuntingCoordinatorDelegate?
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  func start() {
    let vc = RewardHuntingViewController()
    let viewModel = RewardHuntingViewModel()
    viewModel.actions = RewardHuntingViewModelActions(goBack: goBack, openRewards: openRewards, onClose: onClose)
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = false
    navigationController.pushViewController(vc, animated: true)
  }
  
  private func goBack() {
    navigationController.popViewController(animated: true, completion: nil)
  }
  
  private func openRewards() {
    delegate?.openRewards()
  }
  
  private func onClose() {
    navigationController.popViewController(animated: true, completion: nil)
  }
  
}
