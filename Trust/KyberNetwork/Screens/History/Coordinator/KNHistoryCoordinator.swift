// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

class KNHistoryCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession

  var coordinators: [Coordinator] = []

  weak var delegate: KNSessionDelegate?

  lazy var rootViewController: KNHistoryViewController = {
    let controller = KNHistoryViewController(delegate: self)
    controller.loadViewIfNeeded()
    return controller
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.applyStyle()
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.historyTransactionsDidUpdate(nil)
    self.addObserveNotification()
  }

  fileprivate func addObserveNotification() {
    let name = Notification.Name(kTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.historyTransactionsDidUpdate(_:)),
      name: name,
      object: nil
    )
  }

  func stop() {
    self.removeObserveNotification()
  }

  fileprivate func removeObserveNotification() {
    let name = Notification.Name(kTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: name,
      object: nil
    )
  }

  @objc func historyTransactionsDidUpdate(_ sender: Any?) {
    let transactions: [KNHistoryTransaction] = self.session.storage.historyTransactions
    self.rootViewController.coordinatorUpdateHistoryTransactions(transactions)
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewControllerDidSelectTransaction(_ transaction: KNHistoryTransaction) {
    if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(transaction.id)") {
      let controller = SFSafariViewController(url: url)
      self.navigationController.topViewController?.present(controller, animated: true, completion: nil)
    }
  }

  func historyViewControllerDidClickExit() {
    self.stop()
    self.delegate?.userDidClickExitSession()
  }
}
