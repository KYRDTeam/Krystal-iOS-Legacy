//
//  CreateChainWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 09/05/2022.
//

import UIKit

protocol CreateChainWalletMenuCoordinatorDelegate: AnyObject {
  func onSelectCreateNewWallet()
  func onSelectImportWallet()
}

class CreateChainWalletMenuCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  
  var chainType: ChainType
  var parentViewController: UIViewController
  weak var delegate: CreateChainWalletMenuCoordinatorDelegate?
  var transitionDelegate = TransitionDelegate()
  
  init(parentViewController: UIViewController, chainType: ChainType, delegate: CreateChainWalletMenuCoordinatorDelegate?) {
    self.parentViewController = parentViewController
    self.chainType = chainType
    self.delegate = delegate
  }
  
  func start() {
    let vc = CreateChainWalletMenuViewController.instantiateFromNib()
    vc.modalPresentationStyle = .custom
    vc.transitioningDelegate = transitionDelegate
    
    let presenter = CreateChainWalletMenuPresenter(view: vc, chainType: chainType)
    vc.presenter = presenter
    vc.coordinator = self
    
    parentViewController.present(vc, animated: true, completion: nil)
  }
  
  func onClose() {
    parentViewController.dismiss(animated: true)
  }
  
  func selectCreateNewWallet() {
    parentViewController.dismiss(animated: true) { [weak self] in
      self?.delegate?.onSelectCreateNewWallet()
    }
  }
  
  func selectImportWallet() {
    parentViewController.dismiss(animated: true) { [weak self] in
      self?.delegate?.onSelectImportWallet()
    }
    
  }
}
