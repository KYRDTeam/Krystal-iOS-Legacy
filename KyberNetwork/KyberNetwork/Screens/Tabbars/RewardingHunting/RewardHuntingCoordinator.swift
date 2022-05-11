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
  let session: KNSession
  let url: URL
  
  init(navigationController: UINavigationController, session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    let url = URL(string: KNEnvironment.default.krystalWebUrl + "/" + Constants.rewardHuntingPath)!
      .appending("address", value: session.wallet.addressString)
    self.url = url
  }
  
  func start() {
    let vc = RewardHuntingViewController()
    let viewModel = RewardHuntingViewModel(url: url)
    viewModel.actions = RewardHuntingViewModelActions(goBack: goBack, openRewards: openRewards)
    vc.viewModel = viewModel
    vc.hidesBottomBarWhenPushed = true
    navigationController.pushViewController(vc, animated: true)
  }
  
  private func goBack() {
    navigationController.popViewController(animated: true, completion: nil)
  }
  
  private func openRewards() {
    let coordinator = RewardCoordinator(navigationController: navigationController, session: session)
    coordinator.start()
  }
  
}

