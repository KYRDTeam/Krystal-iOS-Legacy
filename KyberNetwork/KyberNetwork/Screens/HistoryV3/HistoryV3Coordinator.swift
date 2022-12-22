//
//  HistoryV3Coordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import UIKit
import BaseModule

class HistoryV3Coordinator: Coordinator {
    var coordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = HistoryV3ViewController.instantiateFromNib()
        navigationController.pushViewController(vc, animated: true)
    }
    
}
