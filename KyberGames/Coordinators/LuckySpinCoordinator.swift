//
//  LuckySpinCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import Foundation
import UIKit

class LuckySpinCoordinator: BaseCoordinator {
  var navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  override func start() {
    let vc = LuckySpinViewController.instantiateFromNib()
    let viewModel = LuckySpinViewModel()
    
    viewModel.onTapBack = { [weak self] in
      self?.navigationController.popViewController(animated: true)
      self?.onCompleted?()
    }
    
    viewModel.onTapAddTurns = { [weak self] in
      self?.openGameTasks()
    }
    
    vc.viewModel = viewModel
    navigationController.pushViewController(vc, animated: true)
  }
  
  func openGameTasks() {
    let coordinator = GameTasksCoordinator(navigationController: navigationController)
    coordinate(coordinator: coordinator)
  }
  
}
