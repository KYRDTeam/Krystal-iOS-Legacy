//
//  Coordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

protocol Coordinator : AnyObject {
  var childCoordinators : [Coordinator] { get set }
  func start()
}

extension Coordinator {
  
  func store(coordinator: Coordinator) {
    childCoordinators.append(coordinator)
  }
  
  func free(coordinator: Coordinator) {
    childCoordinators = childCoordinators.filter { $0 !== coordinator }
  }
  
  func coordinate(coordinator: Coordinator) {
    store(coordinator: coordinator)
    coordinator.start()
  }
  
}

class BaseCoordinator: Coordinator {
  var childCoordinators : [Coordinator] = []
  var onCompleted: (() -> ())?
  
  func start() {
    fatalError("Children must implement `start`.")
  }
}
