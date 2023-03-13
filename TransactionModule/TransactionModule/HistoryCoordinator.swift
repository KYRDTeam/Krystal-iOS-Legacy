//
//  TransactionCoordinator.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import BaseModule
import UIKit
import BaseWallet

public class HistoryCoordinator: Coordinator {
    public var coordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        
    }
    
    public static func createHistoryViewController(chain: ChainType) -> UIViewController {
        let vc = TxHistoryViewController.instantiateFromNib()
        let viewModel = TxHistoryViewModel(chain: chain)
        vc.viewModel = viewModel
        return vc
    }
    
}
