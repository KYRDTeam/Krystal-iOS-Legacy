//
//  ApprovalsCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation
import UIKit

class ApprovalsCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    let navigationController: UINavigationController
    
    var onCompleted: (() -> ())?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = ApprovalListViewController.instantiateFromNib()
        let viewModel = ApprovalListViewModel(
            actions: .init(onTapBack: {
                self.navigationController.popViewController(animated: true, completion: nil)
                self.onCompleted?()
            })
        )
        vc.viewModel = viewModel
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
}
