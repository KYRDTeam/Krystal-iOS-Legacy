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
  var session: KNSession
  
  init(navigationController: UINavigationController, session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  func start() {
    let vc = RewardHuntingViewController()
    let viewModel = RewardHuntingViewModel(session: session)
    viewModel.actions = RewardHuntingViewModelActions(goBack: goBack, openRewards: openRewards, onUpdateSession: onUpdateSession, onClose: onClose)
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = false
    navigationController.pushViewController(vc, animated: true)
  }
  
  private func onUpdateSession(session: KNSession) {
    self.session = session
  }
  
  private func goBack() {
    navigationController.popViewController(animated: true, completion: nil)
  }
  
  private func openRewards() {
    let coordinator = RewardCoordinator(navigationController: navigationController, session: session)
    coordinate(coordinator: coordinator)
  }
  
  private func onClose() {
    navigationController.popViewController(animated: true, completion: nil)
  }
  
}

