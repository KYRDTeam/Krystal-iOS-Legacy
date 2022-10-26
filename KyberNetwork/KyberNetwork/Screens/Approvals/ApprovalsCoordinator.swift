//
//  ApprovalsCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation
import UIKit
import Dependencies
import FittedSheets
import Services

class ApprovalsCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    let navigationController: UINavigationController
    var viewModel: ApprovalListViewModel?
    
    var onCompleted: (() -> ())?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = ApprovalListViewController.instantiateFromNib()
        let viewModel = ApprovalListViewModel(
            actions: .init(
                onTapBack: { [weak self] in
                    self?.navigationController.popViewController(animated: true, completion: nil)
                    self?.onCompleted?()
                },
                onTapHistory: { [weak self] in
                    self?.openHistory()
                },
                onTapRevoke: { [weak self] approval in
                    self?.openRevokeConfirm(approval: approval)
                }
            )
        )
        self.viewModel = viewModel
        vc.viewModel = viewModel
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    func openHistory() {
        AppDependencies.router.openTransactionHistory()
    }
    
    func openRevokeConfirm(approval: Approval) {
        let viewModel = RevokeConfirmViewModel(approval: approval)
        let vc = RevokeConfirmPopup.instantiateFromNib()
        vc.viewModel = viewModel
        vc.onSelectRevoke = { [weak self] in
            self?.viewModel?.requestRevoke()
        }
        
        let options = SheetOptions(pullBarHeight: 0)
        let sheet = SheetViewController(controller: vc, sizes: [.intrinsic], options: options)
        navigationController.present(sheet, animated: true, completion: nil)
    }
}
