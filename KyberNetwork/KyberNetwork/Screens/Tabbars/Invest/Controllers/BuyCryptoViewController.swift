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
  case buyCrypto
}

protocol BuyCryptoViewControllerDelegate: class {
  func buyCryptoViewController(_ controller: BuyCryptoViewController, run event: BuyCryptoEvent)
}

class BuyCryptoViewModel {
  var wallet: Wallet?
}

class BuyCryptoViewController: KNBaseViewController {
  @IBOutlet weak var walletsListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  weak var delegate: BuyCryptoViewControllerDelegate?
  let viewModel = BuyCryptoViewModel()
  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateUI()
  }
  
  func updateUI() {
    self.walletsListButton.setTitle(self.viewModel.wallet?.address.description, for: .normal)
  }
  
  func coordinatorDidUpdateWallet(_ wallet: Wallet) {
    self.viewModel.wallet = wallet
    guard self.isViewLoaded else { return }
    self.updateUI()
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

  @IBAction func buyNowButtonTapped(_ sender: Any) {
    self.delegate?.buyCryptoViewController(self, run: .buyCrypto)
  }
}
