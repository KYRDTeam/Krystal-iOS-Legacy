//
//  CreateChainWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 09/05/2022.
//

import UIKit

protocol CreateChainWalletMenuCoordinatorDelegate: AnyObject {
  func onSelectCreateNewWallet(chain: ChainType)
  func onSelectImportWallet()
}

class CreateChainWalletMenuCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  
  var chainType: ChainType
  var parentViewController: UIViewController
  var viewController: UIViewController?
  weak var delegate: CreateChainWalletMenuCoordinatorDelegate?
  var transitionDelegate = TransitionDelegate()
  
  var onCompleted: (() -> ())?
  
  init(parentViewController: UIViewController, chainType: ChainType, delegate: CreateChainWalletMenuCoordinatorDelegate?) {
    self.parentViewController = parentViewController
    self.chainType = chainType
    self.delegate = delegate
  }
  
  func start() {
    let vc = CreateChainWalletMenuViewController.instantiateFromNib()
    vc.modalPresentationStyle = .custom
    vc.transitioningDelegate = transitionDelegate
    
    let viewModel = CreateChainWalletMenuViewModel(
      chainType: chainType,
      actions: CreateChainWalletMenuViewModelActions(
        onSelectCreateNewWallet: selectCreateNewWallet,
        onSelectImportWallet: selectImportWallet,
        onClose: onClose
      )
    )
    vc.viewModel = viewModel
    viewController = vc
    parentViewController.present(vc, animated: true, completion: nil)
  }
  
  func onClose() {
    viewController?.dismiss(animated: true) { [weak self] in
      self?.parentViewController.dismiss(animated: true)
    }
    
  }
  
  func selectCreateNewWallet() {
    parentViewController.dismiss(animated: true) { [weak self] in
      guard let self = self else { return }
      self.delegate?.onSelectCreateNewWallet(chain: self.chainType)
      self.onCompleted?()
    }
  }
  
  func selectImportWallet() {
    parentViewController.dismiss(animated: true) { [weak self] in
      self?.delegate?.onSelectImportWallet()
      self?.onCompleted?()
    }
    
  }
}
