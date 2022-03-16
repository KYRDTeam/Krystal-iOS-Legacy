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
  case selectNetwork(networks: [FiatNetwork])
  case selectFiat(fiat: [FiatModel])
  case selectCrypto(crypto: [FiatModel])
  case scanQRCode
}

protocol BuyCryptoViewControllerDelegate: class {
  func buyCryptoViewController(_ controller: BuyCryptoViewController, run event: BuyCryptoEvent)
  func didBuyCrypto(_ buyCryptoModel: BifinityOrder)
}

class BuyCryptoViewModel {
  var wallet: Wallet
  var dataSource: [FiatCryptoModel]?
  var currentNetworks: [FiatNetwork]?
  var fiatCurrency: [FiatModel]?
  var cryptoCurrency: [FiatModel]?
  init(wallet: Wallet) {
    self.wallet = wallet
  }
  
}

class BuyCryptoViewController: KNBaseViewController {
  @IBOutlet weak var walletsListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var cryptoButton: UIButton!
  @IBOutlet weak var fiatButton: UIButton!
  @IBOutlet weak var networkLabel: UILabel!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var cryptoInputView: UIView!
  @IBOutlet weak var fiatInputView: UIView!
  @IBOutlet weak var addressInputView: UIView!
  @IBOutlet weak var fiatTextField: UITextField!
  @IBOutlet weak var cryptoTextField: UITextField!
  @IBOutlet weak var networkInputView: UIView!
  @IBOutlet weak var rateLabel: UILabel!
  //  var buyCryptoModel: BuyCryptoModel?

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
    self.addressTextField.text = self.viewModel.wallet.address.description
    self.updateUIPendingTxIndicatorView()
  }

  func updateRateUI() {
    if let model = self.currentFiatCryptoModel() {
      self.rateLabel.text = "Rate: 1\(model.cryptoCurrency) = \(model.quotation) \(model.fiatCurrency)"
      // save supported networks for selected fiat and crypto pair to view model
      self.viewModel.currentNetworks = model.networks
    }
  }

  func updateNetworkUI(network: FiatNetwork?) {
    guard let network = network else {
      return
    }
    self.networkLabel.text = network.name
  }

  func setDefaultValue() {
    self.viewModel.dataSource?.forEach({ model in
      if model.cryptoCurrency == KNGeneralProvider.shared.quoteToken {
        self.cryptoButton.titleLabel?.text = KNGeneralProvider.shared.quoteToken
      }
    })

    self.viewModel.dataSource?.forEach({ model in
      if model.fiatCurrency == "USD" && model.cryptoCurrency == KNGeneralProvider.shared.quoteToken {
        self.cryptoButton.setTitle(model.cryptoCurrency, for: .normal)
        self.updateNetworkUI(network: model.networks.first(where: { network in
          network.name == KNGeneralProvider.shared.currentChain.chainShortName()
        }))
      }
    })
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

  func currentFiatCryptoModel() -> FiatCryptoModel? {
    var fiatCryptoModel: FiatCryptoModel?
    self.viewModel.dataSource?.forEach({ model in
      if model.fiatCurrency == self.fiatButton.titleLabel?.text && model.cryptoCurrency == self.cryptoButton.titleLabel?.text {
        fiatCryptoModel = model
      }
    })
    return fiatCryptoModel
  }

  func coordinatorDidUpdateWallet(_ wallet: Wallet) {
    self.viewModel.wallet = wallet
    guard self.isViewLoaded else { return }
    self.updateUI()
    self.setDefaultValue()
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
    self.updateRateUI()
    self.updateNetworkUI(network: self.viewModel.currentNetworks?.first)
  }

  func coordinatorDidSelectNetwork(network: FiatNetwork) {
    self.networkLabel.text = network.name
    self.networkInputView.layer.borderColor = UIColor.clear.cgColor
    self.networkInputView.layer.borderWidth = 1.0
  }
  
  func coordinatorDidScanAddress(address: String) {
    self.addressTextField.text = address
  }

  func coordinatorDidUpdateFiatCrypto(data: [FiatCryptoModel]) {
    var fiatCurrency: [FiatModel] = []
    var cryptoCurrency: [FiatModel] = []

    data.forEach { model in
      let fiat = FiatModel(url: model.fiatLogo, currency: model.fiatCurrency, name: model.fiatName)

      let crypto = FiatModel(url: model.cryptoLogo, currency: model.cryptoCurrency, name: model.cryptoCurrency)
      let isContainFiat = fiatCurrency.contains { fiatModel in
        fiatModel.currency == fiat.currency
      }
      if !isContainFiat {
        fiatCurrency.append(fiat)
      }

      let isContainCrypto = cryptoCurrency.contains { cryptoModel in
        cryptoModel.currency == crypto.currency
      }
      if !isContainCrypto {
        cryptoCurrency.append(crypto)
      }
    }
    self.viewModel.dataSource = data
    self.viewModel.fiatCurrency = fiatCurrency
    self.viewModel.cryptoCurrency = cryptoCurrency
    guard let cryptoCurrency = self.cryptoButton.titleLabel?.text, !cryptoCurrency.isEmpty else {
      self.setDefaultValue()
      self.updateRateUI()
      return
    }
    self.updateRateUI()
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
    guard let buyCryptoModel = self.validateInput() else {
      return
    }
    self.delegate?.didBuyCrypto(buyCryptoModel)
  }

  @IBAction func selectFiatButtonTapped(_ sender: Any) {
    guard let fiatCurrency = self.viewModel.fiatCurrency else { return }
    self.delegate?.buyCryptoViewController(self, run: .selectFiat(fiat: fiatCurrency))
  }

  @IBAction func selectCryptoButtonTapped(_ sender: Any) {
    guard let cryptoCurrency = self.viewModel.cryptoCurrency else { return }
    self.delegate?.buyCryptoViewController(self, run: .selectCrypto(crypto: cryptoCurrency))
  }

  @IBAction func selectNetworkButtonTapped(_ sender: Any) {
    guard let networks = self.viewModel.currentNetworks else { return }
    self.delegate?.buyCryptoViewController(self, run: .selectNetwork(networks: networks))
  }

  @IBAction func scanAddressButtonTapped(_ sender: Any) {
    self.delegate?.buyCryptoViewController(self, run: .scanQRCode)
  }

  func validateInput() -> BifinityOrder? {
    // validate fiat input
    guard let fiatAmount = self.fiatTextField.text, !fiatAmount.isEmpty else {
      self.shakeViewError(viewToShake: self.fiatInputView)
      showErrorTopBannerMessage(message: "Please input your spent amount")
      return nil
    }

    guard let currentFiatModel = self.currentFiatCryptoModel() else { return nil }
    guard let inputAmount = self.fiatTextField.text?.doubleValue, inputAmount <= currentFiatModel.maxLimit  else {
      self.shakeViewError(viewToShake: self.fiatInputView)
      showErrorTopBannerMessage(message: "Please place an order of less than \(currentFiatModel.maxLimit) \(currentFiatModel.fiatCurrency)")
      return nil
    }

    guard let inputAmount = self.fiatTextField.text?.doubleValue, inputAmount >= currentFiatModel.minLimit  else {
      self.shakeViewError(viewToShake: self.fiatInputView)
      showErrorTopBannerMessage(message: "Minimum spend amount should be more than \(currentFiatModel.minLimit) \(currentFiatModel.fiatCurrency)")
      return nil
    }

    guard let fiatCurrency = self.fiatButton.titleLabel?.text, !fiatCurrency.isEmpty else {
      self.shakeViewError(viewToShake: self.fiatInputView)
      showErrorTopBannerMessage(message: "Please select your currency")
      return nil
    }

    // validate crypto input
    guard let cryptoAmount = self.cryptoTextField.text, !cryptoAmount.isEmpty else {
      self.shakeViewError(viewToShake: self.cryptoInputView)
      showErrorTopBannerMessage(message: "Invalid crypto amount")
      return nil
    }

    guard let cryptoCurrency = self.cryptoButton.titleLabel?.text, !cryptoCurrency.isEmpty else {
      self.shakeViewError(viewToShake: self.cryptoInputView)
      showErrorTopBannerMessage(message: "Please select received crypto currency")
      return nil
    }

    // validate address
    guard let address = self.addressTextField.text, !address.isEmpty else {
      self.shakeViewError(viewToShake: self.addressInputView)
      showErrorTopBannerMessage(message: "Invalid recipient address")
      return nil
    }

    // validate network
    if self.networkLabel.text == "Select Network" {
      self.shakeViewError(viewToShake: self.networkInputView)
      showErrorTopBannerMessage(message: "Please select your network")
      return nil
    }

    let buyCryptoModel = BifinityOrder(cryptoAddress: address, cryptoCurrency: cryptoCurrency, cryptoNetwork: self.networkLabel.text ?? "", fiatCurrency: fiatCurrency, merchantOrderId: "", orderAmount: fiatAmount.doubleValue, requestPrice: currentFiatModel.quotation, userWallet: self.viewModel.wallet.address.description, fiatLogo: "", cryptoLogo: "", networkLogo: "", status: "", executePrice: 0, createdTime: 0, errorCode: "", errorReason: "")

    return buyCryptoModel
  }

  func shakeViewError(viewToShake: UIView) {
    viewToShake.layer.borderColor = UIColor.red.cgColor
    viewToShake.layer.borderWidth = 1.0
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 2
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x - 10, y: viewToShake.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x + 10, y: viewToShake.center.y))

    viewToShake.layer.add(animation, forKey: "position")
  }
}

extension BuyCryptoViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == self.fiatTextField {
      self.fiatInputView.layer.borderColor = UIColor.clear.cgColor
      self.fiatInputView.layer.borderWidth = 1.0
    } else if textField == self.cryptoTextField {
      self.cryptoInputView.layer.borderColor = UIColor.clear.cgColor
      self.cryptoInputView.layer.borderWidth = 1.0
    } else if textField == self.addressTextField {
      self.addressInputView.layer.borderColor = UIColor.clear.cgColor
      self.addressInputView.layer.borderWidth = 1.0
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let currentFiatModel = self.currentFiatCryptoModel() else { return }
    var fiatValue: Double = 0
    let containView: UIView = textField == self.fiatTextField ? self.fiatInputView : self.cryptoInputView
    if textField == self.fiatTextField {
      fiatValue = textField.text?.doubleValue ?? 0
    } else if textField == self.cryptoTextField {
      let cryptoValue = textField.text?.doubleValue ?? 0
      fiatValue = cryptoValue * currentFiatModel.quotation
    } else {
      return
    }

    if fiatValue > currentFiatModel.maxLimit {
      self.shakeViewError(viewToShake: containView)
      showErrorTopBannerMessage(message: "Please place an order of less than \(currentFiatModel.maxLimit) \(currentFiatModel.fiatCurrency)")
      return
    }
    if fiatValue < currentFiatModel.minLimit {
      self.shakeViewError(viewToShake: containView)
      showErrorTopBannerMessage(message: "Minimum spend amount should be more than \(currentFiatModel.minLimit) \(currentFiatModel.fiatCurrency)")
      return
    }

    if textField == self.fiatTextField {
      self.cryptoTextField.text = StringFormatter.amountString(value: fiatValue / currentFiatModel.quotation)
    }
  }
}
