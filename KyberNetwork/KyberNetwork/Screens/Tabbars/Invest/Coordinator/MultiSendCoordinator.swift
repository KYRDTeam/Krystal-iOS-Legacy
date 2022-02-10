//
//  MultiSendCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import Foundation

class MultiSendCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  
  weak var delegate: KNSendTokenViewCoordinatorDelegate?
  
  lazy var rootViewController: MultiSendViewController = {
    let controller = MultiSendViewController()
    controller.delegate = self
    return controller
  }()
  
  fileprivate(set) var searchTokensVC: KNSearchTokenViewController?
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
  }
  
  func stop() {
    
  }
}

extension MultiSendCoordinator: MultiSendViewControllerDelegate {
  func multiSendViewController(_ controller: MultiSendViewController, run event: MultiSendViewControllerEvent) {
    switch event {
    case .searchToken(let selectedToken):
      self.openSearchToken(selectedToken: selectedToken.toObject())
    }
  }
  
  fileprivate func openSearchToken(selectedToken: TokenObject) {
    let tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
    let viewModel = KNSearchTokenViewModel(
      supportedTokens: tokens
    )
    let controller = KNSearchTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.searchTokensVC = controller
  }
}

extension MultiSendCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true) {
      self.searchTokensVC = nil
      if case .select(let token) = event {
        self.rootViewController.coordinatorDidUpdateSendToken(token.toToken())
      } else if case .add(let token) = event {
        self.delegate?.sendTokenCoordinatorDidSelectAddToken(token)
      }
    }
  }
}
