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
  
  lazy var addContactVC: KNNewContactViewController = {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: "")
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
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
    case .openContactsList:
      self.openListContactsView()
    case .addContact(address: let address):
      self.openNewContact(address: address, ens: nil)
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
  
  fileprivate func openListContactsView() {
    let controller = KNListContactViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  fileprivate func openNewContact(address: String, ens: String?) {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: address, ens: ens)
    self.addContactVC.updateView(viewModel: viewModel)
    self.navigationController.pushViewController(self.addContactVC, animated: true)
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

extension MultiSendCoordinator: KNListContactViewControllerDelegate {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .select(let contact) = event {
        self.rootViewController.coordinatorDidSelectContact(contact)
      } else if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}

extension MultiSendCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}
