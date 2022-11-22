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
import Result

class ApprovalsCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    let navigationController: UINavigationController
    var rootViewController: UIViewController!
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
                },
                onOpenStatus: onOpenTxStatusPopup,
                onTapTokenSymbol: { [weak self] approval in
                    if let tokenAddress = approval.tokenAddress {
                      AppDependencies.router.openToken(address: tokenAddress, chainID: approval.chainId)
                    }
                },
                onTapSpenderAddress: { [weak self] approval in
                    if let spenderAddress = approval.spenderAddress {
                        self?.rootViewController.openAddress(address: spenderAddress, chainID: approval.chainId)
                    }
                }
            )
        )
        self.viewModel = viewModel
        vc.viewModel = viewModel
        vc.hidesBottomBarWhenPushed = true
        self.rootViewController = vc
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
            guard let self = self else { return }
            self.rootViewController.showLoadingHUD()
            self.viewModel?.requestRevoke(approval: approval, setting: viewModel.setting, onCompleted: { error in
                self.rootViewController.hideLoading()
                if let error = error {
                    self.showErrorMessage(AnyError(error), viewController: self.rootViewController)
                }
            })
        }
        
        let options = SheetOptions(pullBarHeight: 0)
        let sheet = SheetViewController(controller: vc, sizes: [.intrinsic], options: options)
        navigationController.present(sheet, animated: true, completion: nil)
    }
    
    func onOpenTxStatusPopup(_ txHash: String, _ chain: ChainType) {
        let popup = RevokeTxStatusPopup.instantiateFromNib()
        popup.txHash = txHash
        popup.chain = chain
        popup.onSelectOpenExplorer = { [weak self] in
            self?.rootViewController.openTxHash(txHash: txHash, chainID: chain.getChainId())
        }
        popup.onSelectContactSupport = { [weak self] in
            self?.rootViewController.openSafari(with: Constants.supportURL)
        }
        let sheetOptions = SheetOptions(pullBarHeight: 0)
        let sheet = SheetViewController(controller: popup, sizes: [.intrinsic], options: sheetOptions)
        navigationController.present(sheet, animated: true)
    }
}
