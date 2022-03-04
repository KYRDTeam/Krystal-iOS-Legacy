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
  case selectFiat(fiat: [FiatModel])
  case selectCrypto(crypto: [FiatModel])
}

protocol BuyCryptoViewControllerDelegate: class {
  func buyCryptoViewController(_ controller: BuyCryptoViewController, run event: BuyCryptoEvent)
}

class BuyCryptoViewModel {
  var wallet: Wallet
  var dataSource: [FiatCryptoModel]?
  var fiatCurrency: [String]?
  var cryptoCurrency: [String]?
  init(wallet: Wallet) {
    self.wallet = wallet
  }
  
}

class BuyCryptoViewController: KNBaseViewController {
  @IBOutlet weak var walletsListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var cryptoButton: UIButton!
  @IBOutlet weak var fiatButton: UIButton!
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
  
  func coordinatorDidSelectFiatCrypto(model: FiatModel, type: SearchCurrencyType) {
    switch type {
    case .fiat:
      self.fiatButton.setTitle(model.currency, for: .normal)
    case .crypto:
      self.cryptoButton.setTitle(model.currency, for: .normal)
    }
  }
  
  func coordinatorDidUpdateFiatCrypto(data: [FiatCryptoModel]) {
    var fiatCurrency: [String] = []
    var cryptoCurrency: [String] = []
    
    data.forEach { model in
      if !fiatCurrency.contains(model.fiatCurrency) {
        fiatCurrency.append(model.fiatCurrency)
      }
      
      if !cryptoCurrency.contains(model.cryptoCurrency) {
        cryptoCurrency.append(model.cryptoCurrency)
      }
    }
    
    self.viewModel.fiatCurrency = fiatCurrency
    self.viewModel.cryptoCurrency = cryptoCurrency
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
  
  @IBAction func selectFiatButtonTapped(_ sender: Any) {
    guard let fiatCurrency = self.viewModel.fiatCurrency else { return }
    var fiatModels: [FiatModel] = []
    fiatCurrency.forEach { item in
      fiatModels.append(FiatModel(url: item, currency: item))
    }
    self.delegate?.buyCryptoViewController(self, run: .selectFiat(fiat: fiatModels))
  }

  @IBAction func selectCryptoButtonTapped(_ sender: Any) {
    guard let cryptoCurrency = self.viewModel.cryptoCurrency else { return }
    var cryptoModels: [FiatModel] = []
    cryptoCurrency.forEach { item in
      cryptoModels.append(FiatModel(url: item, currency: item))
    }
    self.delegate?.buyCryptoViewController(self, run: .selectCrypto(crypto: cryptoModels))
  }
}
