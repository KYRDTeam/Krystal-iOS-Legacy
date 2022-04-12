//
//  GameTasksCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import Foundation
import UIKit

class GameTasksCoordinator: BaseCoordinator {
  let navigationController: UINavigationController
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  override func start() {
    let vc = GameTasksViewController.instantiateFromNib()
    let viewModel = GameTasksViewModel()
    
    viewModel.onTapBack = { [weak self] in
      self?.navigationController.popViewController(animated: true)
      self?.onCompleted?()
    }
    
    vc.viewModel = viewModel
    navigationController.pushViewController(vc, animated: true)
  }
  
}
