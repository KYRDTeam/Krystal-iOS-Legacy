//
//  TransactionCoordinator.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import BaseModule
import UIKit

public class HistoryCoordinator: Coordinator {
    public var coordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let vc = TxHistoryViewController.instantiateFromNib()
        let viewModel = TxHistoryViewModel()
        vc.viewModel = viewModel
        navigationController.pushViewController(vc, animated: true)
    }
    
}
