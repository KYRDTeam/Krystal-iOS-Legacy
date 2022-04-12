//
//  Coordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

protocol Coordinator {
    var parentCoordinator: Coordinator? { get set }
    var children: [Coordinator] { get set }
    
    func start()
}
