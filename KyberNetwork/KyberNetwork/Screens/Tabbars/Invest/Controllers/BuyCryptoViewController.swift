//
//  BuyCryptoViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 23/02/2022.
//

import UIKit

enum BuyCryptoEvent {
  case openHistory
  case openWalletsList
  case updateRate
  case buyCrypto
}

protocol BuyCryptoViewControllerDelegate: class {
  func buyCryptoViewController(_ controller: BuyCryptoViewController, run event: BuyCryptoEvent)
}

class BuyCryptoViewModel {
  var wallet: Wallet
  init(wallet: Wallet) {
    self.wallet = wallet
  }
}

class BuyCryptoViewController: KNBaseViewController {
  @IBOutlet weak var walletsListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  weak var delegate: BuyCryptoViewControllerDelegate?
  let transitor = TransitionDelegate()
  let viewModel: BuyCryptoViewModel
  
  init(viewModel: BuyCryptoViewModel) {
    self.viewModel = viewModel
    super.init(nibName: BuyCryptoViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateUI()
  }
  
  func updateUI() {
    self.walletsListButton.setTitle(self.viewModel.wallet.address.description, for: .normal)
    self.updateUIPendingTxIndicatorView()
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
  
  func coordinatorDidUpdateWallet(_ wallet: Wallet) {
    self.viewModel.wallet = wallet
    guard self.isViewLoaded else { return }
    self.updateUI()
  }

  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func historyListButtonTapped(_ sender: UIButton) {
    self.delegate?.buyCryptoViewController(self, run: .openHistory)
  }

  @IBAction func walletsListButtonTapped(_ sender: UIButton) {
    self.delegate?.buyCryptoViewController(self, run: .openWalletsList)
  }
  
  @IBAction func updateRateButtonTapped(_ sender: Any) {
    self.delegate?.buyCryptoViewController(self, run: .updateRate)
  }
  
  @IBAction func buyNowButtonTapped(_ sender: Any) {
    self.delegate?.buyCryptoViewController(self, run: .buyCrypto)
  }
}
