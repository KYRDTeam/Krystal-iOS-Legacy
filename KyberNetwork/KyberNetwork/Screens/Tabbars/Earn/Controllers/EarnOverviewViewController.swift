//
//  EarnOverviewViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/5/21.
//

import UIKit
import BigInt
import KrystalWallets

protocol EarnOverviewViewControllerDelegate: class {
  func earnOverviewViewControllerDidSelectExplore(_ controller: EarnOverviewViewController)
  func earnOverviewViewControllerAddChainWallet(_ controller: EarnOverviewViewController, chainType: ChainType)
}

class EarnOverviewViewController: KNBaseViewController {
  @IBOutlet weak var exploreButton: UIButton!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var currentChainIcon: UIImageView!

  weak var delegate: EarnOverviewViewControllerDelegate?
  weak var navigationDelegate: NavigationBarDelegate?

  let depositViewController: OverviewDepositViewController
  var firstTimeLoaded: Bool = false
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }

  init(_ controller: OverviewDepositViewController) {
    self.depositViewController = controller
    super.init(nibName: EarnOverviewViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.exploreButton.rounded(radius: 16)
    self.addChild(self.depositViewController)
    self.contentView.addSubview(self.depositViewController.view)
    self.depositViewController.didMove(toParent: self)
    self.depositViewController.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
    self.depositViewController.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
    self.depositViewController.view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
    self.depositViewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    self.depositViewController.view.translatesAutoresizingMaskIntoConstraints = false
    self.updateUIWalletSelectButton()
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
    self.updateUISwitchChain()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    MixPanelManager.track("earn_open", properties: ["screenid": "earn"])
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

  fileprivate func updateUISwitchChain() {
    guard self.isViewLoaded else {
      return
    }
    let icon = KNGeneralProvider.shared.chainIconImage
    self.currentChainIcon.image = icon
  }

  @IBAction func exploreButtonTapped(_ sender: UIButton) {
    self.delegate?.earnOverviewViewControllerDidSelectExplore(self)
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }
  
  @IBAction func walletListButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }

  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = { [weak self] selected in
      guard let self = self else { return }
      let addresses = WalletManager.shared.getAllAddresses(addressType: selected.addressType)
      if addresses.isEmpty {
        self.delegate?.earnOverviewViewControllerAddChainWallet(self, chainType: selected)
        return
      } else {
        let viewModel = SwitchChainWalletsListViewModel(selected: selected)
        let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
        self.present(secondPopup, animated: true, completion: nil)
      }
    }
    self.present(popup, animated: true, completion: nil)
  }

  fileprivate func updateUIWalletSelectButton() {
    self.walletListButton.setTitle(currentAddress.name, for: .normal)
  }
  
  func coordinatorAppSwitchAddress() {
    if self.isViewLoaded {
      self.updateUIWalletSelectButton()
      self.depositViewController.coordinatorAppSwitchAddress()
      self.updateUIPendingTxIndicatorView()
      self.updateUIPendingTxIndicatorView()
    }
  }

  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }
  
  func coordinatorDidUpdateChain() {
    self.updateUISwitchChain()
  }

  func coordinatorDidUpdateHideBalanceStatus(_ status: Bool) {
    self.depositViewController.containerDidUpdateHideBalanceStatus(status)
  }

  func coordinatorDidUpdateDidUpdateTokenList() {
    self.depositViewController.coordinatorDidUpdateDidUpdateTokenList()
  }
}
