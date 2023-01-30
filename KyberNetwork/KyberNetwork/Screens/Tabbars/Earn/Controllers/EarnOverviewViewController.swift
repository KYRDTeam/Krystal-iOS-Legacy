//
//  EarnOverviewViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/5/21.
//

import UIKit
import BigInt
import KrystalWallets
import BaseModule

protocol EarnOverviewViewControllerDelegate: class {
  func earnOverviewViewControllerDidSelectExplore(_ controller: EarnOverviewViewController)
}

class EarnOverviewViewController: InAppBrowsingViewController {
  @IBOutlet weak var exploreButton: UIButton!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var pendingTxIndicatorView: UIView!

  weak var delegate: EarnOverviewViewControllerDelegate?
  weak var navigationDelegate: NavigationBarDelegate?

  let depositViewController: OverviewDepositViewController
  var firstTimeLoaded: Bool = false

  init(_ controller: OverviewDepositViewController) {
    self.depositViewController = controller
    super.init(nibName: EarnOverviewViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    tabBarItem.accessibilityIdentifier = "menuEarn"
    
    self.exploreButton.rounded(radius: 16)
    self.addChild(self.depositViewController)
    self.contentView.addSubview(self.depositViewController.view)
    self.depositViewController.didMove(toParent: self)
    self.depositViewController.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
    self.depositViewController.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
    self.depositViewController.view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
    self.depositViewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    self.depositViewController.view.translatesAutoresizingMaskIntoConstraints = false
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIPendingTxIndicatorView()
    if UserDefaults.standard.bool(forKey: "earn-tutorial" ) == false {
      let tutorial = EarnTutorialViewController()
      tutorial.modalPresentationStyle = .overFullScreen
      self.navigationController?.present(tutorial, animated: true, completion: nil)
      UserDefaults.standard.set(true, forKey: "earn-tutorial")
    }
    if self.depositViewController.viewModel.totalValueBigInt == BigInt(0) {
      if self.firstTimeLoaded == false {
        self.delegate?.earnOverviewViewControllerDidSelectExplore(self)
      }
    }
    self.firstTimeLoaded = true
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    MixPanelManager.track("earn_open", properties: ["screenid": "earn"])
  }
  
  override func reloadWallet() {
    super.reloadWallet()
    
    depositViewController.coordinatorDidUpdateDidUpdateTokenList()
  }
    
    @objc override func onAppSwitchChain() {
      super.onAppSwitchChain()
      reloadWallet()
    }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    let pendingTransaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().first { transaction in
      transaction.state == .pending
    }
    self.pendingTxIndicatorView.isHidden = pendingTransaction == nil
  }

  @IBAction func exploreButtonTapped(_ sender: UIButton) {
    self.delegate?.earnOverviewViewControllerDidSelectExplore(self)
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }
  
  func coordinatorAppSwitchAddress() {
    if self.isViewLoaded {
      self.depositViewController.coordinatorAppSwitchAddress()
      self.updateUIPendingTxIndicatorView()
      self.updateUIPendingTxIndicatorView()
    }
  }

  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }

  func coordinatorDidUpdateHideBalanceStatus(_ status: Bool) {
    self.depositViewController.containerDidUpdateHideBalanceStatus(status)
  }

  func coordinatorDidUpdateDidUpdateTokenList() {
    self.depositViewController.coordinatorDidUpdateDidUpdateTokenList()
  }
}
