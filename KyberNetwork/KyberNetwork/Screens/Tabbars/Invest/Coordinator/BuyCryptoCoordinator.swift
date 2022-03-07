//
//  BuyCryptoCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 23/02/2022.
//
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnectSwift
import Moya
import Darwin

// MARK: - FiatCryptoModel
struct FiatCryptoResponse: Codable {
  let timestamp: Int
  let data: [FiatCryptoModel]
}

struct FiatCryptoModel: Codable {
  let cryptoCurrency: String
  let fiatCurrency: String
  let maxLimit: Double
  let minLimit: Double
  let quotation: Double
  let networks: [String]
}

struct FiatModel: Codable {
  let url: String
  let currency: String
}

protocol BuyCryptoCoordinatorDelegate: class {
  func buyCryptoCoordinatorDidSelectAddWallet()
  func buyCryptoCoordinatorDidSelectWallet(_ wallet: Wallet)
  func buyCryptoCoordinatorDidSelectManageWallet()
  func buyCryptoCoordinatorOpenHistory()
}

class BuyCryptoCoordinator: NSObject, Coordinator {
  var coordinators: [Coordinator] = []
  var session: KNSession
  let navigationController: UINavigationController
  weak var delegate: BuyCryptoCoordinatorDelegate?
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  lazy var rootViewController: BuyCryptoViewController = {
    let viewModel = BuyCryptoViewModel(wallet: self.session.wallet)
    let controller = BuyCryptoViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    self.loadFiatPair()
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorDidUpdateWallet(self.session.wallet)
  }
  
  func appCoordinatorPendingTransactionsDidUpdate() {
    self.rootViewController.coordinatorDidUpdatePendingTx()
  }
  
  func loadFiatPair() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getCryptoFiatPair) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let responseData = try decoder.decode(FiatCryptoResponse.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateFiatCrypto(data: responseData.data)
        } catch let error {
          print("[Load Fiat] \(error.localizedDescription)")
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.loadFiatPair()
          }
        }
      case .failure(let error):
        print("[Load Fiat] \(error.localizedDescription)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          self.loadFiatPair()
        }
      }
    }
  }

}

extension BuyCryptoCoordinator: BuyCryptoViewControllerDelegate {
  func buyCryptoViewController(_ controller: BuyCryptoViewController, run event: BuyCryptoEvent) {
    switch event {
    case .openHistory:
      self.openHistoryScreen()
    case .openWalletsList:
      self.openWalletListView()
    case .updateRate:
      self.updateData()
    case .buyCrypto:
      self.buyCrypto()
    case .selectNetwork:
      self.selectNetwork()
    case .selectFiat(fiat: let fiatModels):
      self.selectFiat(fiat: fiatModels)
    case .selectCrypto(crypto: let cryptoModels):
      self.selectCrypto(crypto: cryptoModels)
    }
  }

  fileprivate func openHistoryScreen() {
    self.delegate?.buyCryptoCoordinatorOpenHistory()
  }

  fileprivate func updateData() {
    self.loadFiatPair()
  }

  fileprivate func selectNetwork() {
    let selectNetworkVC = SelectNetworkViewController()
    selectNetworkVC.delegate = self
    self.navigationController.present(selectNetworkVC, animated: true, completion: nil)
  }

  fileprivate func openWalletListView() {
    let viewModel = WalletsListViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.currentWallet
    )
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }

  fileprivate func buyCrypto() {
    let confirmVC = ConfirmBuyCryptoViewController()
    self.navigationController.present(confirmVC, animated: true, completion: nil)
  }

  fileprivate func selectFiat(fiat: [FiatModel]) {
    let viewModel = SearchFiatCryptoViewModel(dataSource: fiat, currencyType: .fiat)
    let selectFiatVC = SearchFiatCryptoViewController(viewModel: viewModel)
    selectFiatVC.delegate = self
    self.navigationController.present(selectFiatVC, animated: true, completion: nil)
  }

  fileprivate func selectCrypto(crypto: [FiatModel]) {
    let viewModel = SearchFiatCryptoViewModel(dataSource: crypto, currencyType: .crypto)
    let selectFiatVC = SearchFiatCryptoViewController(viewModel: viewModel)
    selectFiatVC.delegate = self
    self.navigationController.present(selectFiatVC, animated: true, completion: nil)
  }
}

extension BuyCryptoCoordinator: SearchFiatCryptoViewControllerDelegate {
  func didSelectCurrency(currency: FiatModel, type: SearchCurrencyType) {
    self.rootViewController.coordinatorDidSelectFiatCrypto(model: currency, type: type)
  }
}

extension BuyCryptoCoordinator: SelectNetworkViewControllerDelegate {
  func didSelectNetwork(chain: String) {
    self.rootViewController.coordinatorDidSelectNetwork(chain: chain)
  }
}

extension BuyCryptoCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.buyCryptoCoordinatorDidSelectManageWallet()
    case .copy(let wallet):
      UIPasteboard.general.string = wallet.address
      let hud = MBProgressHUD.showAdded(to: controller.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    case .select(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      self.delegate?.buyCryptoCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.buyCryptoCoordinatorDidSelectAddWallet()
    }
  }
}

extension BuyCryptoCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let url = WCURL(result) else {
        self.navigationController.showTopBannerView(
          with: "Invalid session".toBeLocalised(),
          message: "Your session is invalid, please try with another QR code".toBeLocalised(),
          time: 1.5
        )
        return
      }

      if case .real(let account) = self.session.wallet.type {
        let result = self.session.keystore.exportPrivateKey(account: account)
        switch result {
        case .success(let data):
          DispatchQueue.main.async {
            let pkString = data.hexString
            let controller = KNWalletConnectViewController(
              wcURL: url,
              knSession: self.session,
              pk: pkString
            )
            self.navigationController.present(controller, animated: true, completion: nil)
          }
          
        case .failure(_):
          self.navigationController.showTopBannerView(
            with: "Private Key Error",
            message: "Can not get Private key",
            time: 1.5
          )
        }
      }
    }
  }
}
