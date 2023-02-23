//
//  DappCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 21/12/2021.
//

import Foundation
import TrustKeystore
import CryptoKit
import Result
import APIKit
import JSONRPCKit
import MBProgressHUD
import WalletConnectSwift
import BigInt
import WebKit
import KrystalWallets
import AppState
import DappBrowser

class DappCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
  }

  private lazy var urlParser: BrowserURLParser = {
      return BrowserURLParser()
  }()
  
  var address: KAddress {
    return AppDelegate.session.address
  }

  func start() {
      DappBrowser.openHome(navigationController: self.navigationController)
  }
  
  func stop() {
    
  }

  func openBrowserScreen(searchText: String) {
    if address.isWatchWallet { return }
    guard let url = urlParser.url(from: searchText.trimmed) else { return }
    DappBrowser.openURL(navigationController: navigationController, url: url)
  }

  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if let trans = self.transactionStatusVC?.transaction, trans.hash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
}

extension DappCoordinator: DappBrowserHomeViewControllerDelegate {
  func dappBrowserHomeViewController(_ controller: DappBrowserHomeViewController, run event: DappBrowserHomeEvent) {
    switch event {
    case .enterText(let text):
      self.openBrowserScreen(searchText: text)
    case .showAllRecently:
      let viewModel = RecentlyHistoryViewModel { item in
        self.openBrowserScreen(searchText: item.url)
      }
      let controller = RecentlyHistoryViewController(viewModel: viewModel)
      self.navigationController.pushViewController(controller, animated: true, completion: nil)
    }
  }
}
