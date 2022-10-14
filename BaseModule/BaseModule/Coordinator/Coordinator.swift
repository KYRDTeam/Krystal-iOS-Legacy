//
//  Coordinator.swift
//  BaseModule
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation

public protocol Coordinator: class {
    var coordinators: [Coordinator] { get set }
    
    func start()
}

public extension Coordinator {
    func addCoordinator(_ coordinator: Coordinator) {
        coordinators.append(coordinator)
    }
    
    func removeCoordinator(_ coordinator: Coordinator) {
        coordinators = coordinators.filter { $0 !== coordinator }
    }
    
    func removeAllCoordinators() {
        coordinators.removeAll()
    }
    
    func coordinate(coordinator: Coordinator) {
        addCoordinator(coordinator)
        coordinator.start()
    }
    
}
