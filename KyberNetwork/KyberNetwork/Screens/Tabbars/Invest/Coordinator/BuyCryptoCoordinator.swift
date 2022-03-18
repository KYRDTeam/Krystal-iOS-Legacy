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
import MBProgressHUD

// MARK: - FiatCryptoModel
struct FiatCryptoResponse: Codable {
  let timestamp: Int
  let data: [FiatCryptoModel]
}

struct FiatCryptoModel: Codable {
  let cryptoCurrency: String
  let fiatCurrency: String
  let fiatName: String
  let fiatLogo: String
  let cryptoLogo: String
  let maxLimit: Double
  let minLimit: Double
  let quotation: Double
  let networks: [FiatNetwork]
}

struct FiatNetwork: Codable {
  let name: String
  let logo: String
}

struct FiatModel: Codable {
  let url: String
  let currency: String
  let name: String
}

//struct BuyCryptoModel: Codable {
//  var cryptoAddress: String
//  var cryptoCurrency: String
//  var cryptoNetWork: String
//  var fiatCurrency: String
//  var orderAmount: Double
//  var requestPrice: Double
//}

struct BifinityOrderResponse: Codable {
  let timestamp: Int
  let data: [BifinityOrder]
}

struct BifinityOrder: Codable {
  let cryptoAddress: String
  let cryptoCurrency: String
  let cryptoNetwork: String
  let fiatCurrency: String
  let merchantOrderId: String
  let orderAmount: Double
  let requestPrice: Double
  let userWallet: String
  let fiatLogo: String
  let cryptoLogo: String
  let networkLogo: String
  /// init, processing ,success, failure
  let status: String
  let executePrice: Double
  // in miliseconds
  let createdTime: Int
  let errorCode: String?
  let errorReason: String?
}

protocol BuyCryptoCoordinatorDelegate: class {
  func buyCryptoCoordinatorDidSelectAddWallet()
  func buyCryptoCoordinatorDidSelectWallet(_ wallet: Wallet)
  func buyCryptoCoordinatorDidSelectManageWallet()
//  func buyCryptoCoordinatorOpenHistory()
}

class BuyCryptoCoordinator: NSObject, Coordinator {
  var coordinators: [Coordinator] = []
  var session: KNSession
  let navigationController: UINavigationController
  weak var delegate: BuyCryptoCoordinatorDelegate?
  var bifinityOrders: [BifinityOrder] = []
  var currentOrder: BifinityOrder?
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
  
  lazy var ordersViewController: BifinityOrderViewController = {
    let viewModel = BifinityOrderViewModel(wallet: self.session.wallet)
    let controller = BifinityOrderViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  lazy var webViewController: WebBrowserViewController = {
    let controller = WebBrowserViewController()
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
    self.ordersViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.getBifinityOrders()
  }

  func appCoordinatorPendingTransactionsDidUpdate() {
    self.rootViewController.coordinatorDidUpdatePendingTx()
  }

  func loadFiatPair() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let hud = MBProgressHUD.showAdded(to: self.rootViewController.view, animated: true)
    provider.request(.getCryptoFiatPair) { (result) in
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let responseData = try decoder.decode(FiatCryptoResponse.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateFiatCrypto(data: responseData.data)
        } catch let error {
          print("[Load Fiat] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Load Fiat] \(error.localizedDescription)")
      }
    }
  }

  func createBuyCryptoOrder(buyCryptoModel: BifinityOrder) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let hud = MBProgressHUD.showAdded(to: self.rootViewController.view, animated: true)
    provider.request(.buyCrypto(buyCryptoModel: buyCryptoModel)) { (result) in
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      if case .success(let resp) = result {
        if let json = try? resp.mapJSON() as? JSONDictionary ?? [:] {
          self.webViewController.urlString = json["eternalRedirectUrl"] as? String
          self.navigationController.present(self.webViewController, animated: true, completion: nil)
          self.currentOrder = buyCryptoModel
        }
      } else {
        print("[Buy crypto][Error]")
      }
    }
  }

  func getBifinityOrders(_ currentOrder: BifinityOrder? = nil) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    var presentView: UIView = self.ordersViewController.view
    if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
      presentView = rootViewController.view
    }

    let hud = MBProgressHUD.showAdded(to: presentView, animated: true)
    provider.request(.getOrders(userWallet: self.session.wallet.address.description)) { (result) in
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let responseData = try decoder.decode(BifinityOrderResponse.self, from: resp.data)
          self.ordersViewController.coordinatorDidGetOrders(orders: responseData.data)
          self.bifinityOrders = responseData.data
          self.showDetailOrderIfNeed(currentOrder)
        } catch let error {
          print("[Get BifinityOrder] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Get BifinityOrder] \(error.localizedDescription)")
      }
    }
  }

  func showDetailOrderIfNeed(_ currentOrder: BifinityOrder?) {
    guard let currentOrder = currentOrder else {
      return
    }
    var newOrder: BifinityOrder?
    var matchOrders: [BifinityOrder] = []
    self.bifinityOrders.forEach { order in
      //TODO: check contain current order here
      if order.cryptoAddress == currentOrder.cryptoAddress
          && order.cryptoCurrency == currentOrder.cryptoCurrency
          && order.cryptoNetwork == currentOrder.cryptoNetwork
          && order.fiatCurrency == currentOrder.fiatCurrency
          && order.orderAmount == currentOrder.orderAmount
          && order.requestPrice == currentOrder.requestPrice
          && order.status == "processing" {
        matchOrders.append(order)
      }
    }

    // only get latest order
    let sortedOrders = matchOrders.sorted { lhs, rhs in
      return lhs.createdTime > rhs.createdTime
    }
    newOrder = sortedOrders.first

    if let newOrder = newOrder {
      let confirmVC = ConfirmBuyCryptoViewController(currentOrder: newOrder)
      self.navigationController.present(confirmVC, animated: true)
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
    case .selectNetwork(networks: let networks):
      self.selectNetwork(networks: networks)
    case .selectFiat(fiat: let fiatModels):
      self.selectFiat(fiat: fiatModels)
    case .selectCrypto(crypto: let cryptoModels):
      self.selectCrypto(crypto: cryptoModels)
    case .scanQRCode:
      self.scanQRCode()
    }
  }
  
  func scanQRCode() {
    if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self.rootViewController) {
      return
    }
    let qrcodeReaderVC: QRCodeReaderViewController = {
      let controller = QRCodeReaderViewController()
      controller.delegate = self
      return controller
    }()
    self.navigationController.present(qrcodeReaderVC, animated: true, completion: nil)
  }
  
  func didBuyCrypto(_ buyCryptoModel: BifinityOrder) {
    self.createBuyCryptoOrder(buyCryptoModel: buyCryptoModel)
  }

  fileprivate func openHistoryScreen() {
    self.getBifinityOrders()
    self.navigationController.pushViewController(self.ordersViewController, animated: true)
  }

  fileprivate func updateData() {
    self.loadFiatPair()
  }

  fileprivate func selectNetwork(networks: [FiatNetwork]) {
    let viewModel = SelectNetworkViewModel(networks: networks)
    let selectNetworkVC = SelectNetworkViewController(viewModel: viewModel)
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
  func didSelectNetwork(network: FiatNetwork) {
    self.rootViewController.coordinatorDidSelectNetwork(network: network)
  }
}

extension BuyCryptoCoordinator: WebBrowserViewControllerDelegate {
  func didClose() {
    self.getBifinityOrders(self.currentOrder)
  }
}

extension BuyCryptoCoordinator: BifinityOrderDelegate {
  func openWalletList() {
    self.openWalletListView()
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
      let address: String = {
        if result.count < 42 { return result }
        if result.starts(with: "0x") { return result }
        let string = "\(result.suffix(42))"
        if string.starts(with: "0x") { return string }
        return result
      }()
      self.rootViewController.coordinatorDidScanAddress(address: address)
    }
  }
}
