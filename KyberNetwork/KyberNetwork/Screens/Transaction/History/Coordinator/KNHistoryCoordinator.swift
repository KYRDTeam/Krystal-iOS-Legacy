// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import BigInt
import Moya
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnectSwift
import KrystalWallets
import BaseModule

protocol KNHistoryCoordinatorDelegate: class {
  func historyCoordinatorDidClose()
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject)
}

class KNHistoryCoordinator: NSObject, Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  let navigationController: UINavigationController
  
  var session: KNSession {
    return AppDelegate.session
  }

  var sendCoordinator: KNSendTokenViewCoordinator?

  var coordinators: [Coordinator] = []
  weak var delegate: KNHistoryCoordinatorDelegate?
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  var etherScanURL: String {
    return KNGeneralProvider.shared.customRPC.etherScanEndpoint
  }

  lazy var rootViewController: KNHistoryViewController = {
    let viewModel = KNHistoryViewModel()
    let controller = KNHistoryViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  var txDetailsCoordinator: KNTransactionDetailsCoordinator?

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  func start() {
    EtherscanTransactionStorage.shared.updateCurrentHistoryCache()
    self.navigationController.pushViewController(self.rootViewController, animated: true) {
      self.appCoordinatorTokensTransactionsDidUpdate(showLoading: true)
      self.appCoordinatorPendingTransactionDidUpdate()
      self.rootViewController.coordinatorUpdateTokens()
      if KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        AppDelegate.session.transactionCoordinator?.loadEtherscanTransactions()
      }
    }
    self.observeAppEvents()
  }

  func stop() {
    self.removeObservers()
    self.navigationController.popViewController(animated: true) {
      self.delegate?.historyCoordinatorDidClose()
    }
  }
  
  func removeObservers() {
      NotificationCenter.default.removeObserver(
        self,
        name: AppEventCenter.shared.kAppDidChangeAddress,
        object: nil
      )
      NotificationCenter.default.removeObserver(
        self,
        name: Notification.Name(kTransactionDidUpdateNotificationKey),
        object: nil
      )
  }
    
  func observeAppEvents() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidSwitchAddress),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
      
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(appDidUpdateTransactions),
        name: Notification.Name(kTransactionDidUpdateNotificationKey),
        object: nil
      )
    
    let tokenTxListName = Notification.Name(kTokenTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(tokenTransactionListDidUpdate),
      name: tokenTxListName,
      object: nil
    )
  }
    
    @objc func appDidUpdateTransactions() {
        appCoordinatorPendingTransactionDidUpdate()
    }
  
  @objc func appDidSwitchAddress() {
    self.appCoordinatorTokensTransactionsDidUpdate()
    self.rootViewController.coordinatorUpdateTokens()
    self.appCoordinatorPendingTransactionDidUpdate()
    self.rootViewController.coordinatorAppSwitchAddress()
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }
  
  @objc func tokenTransactionListDidUpdate() {
    self.appCoordinatorTokensTransactionsDidUpdate()
    self.rootViewController.coordinatorDidUpdateTransaction()
  }

  func appCoordinatorTokensTransactionsDidUpdate(showLoading: Bool = false) {
    if showLoading { self.navigationController.displayLoading() }
    DispatchQueue.global(qos: .background).async {
      let dates: [String] = {
        let dates = EtherscanTransactionStorage.shared.getKrystalTransaction().map { return self.dateFormatter.string(from: $0.date) }
        var uniqueDates = [String]()
        dates.forEach({
          if !uniqueDates.contains($0) { uniqueDates.append($0) }
        })
        return uniqueDates
      }()
      let sectionData: [String: [KrystalHistoryTransaction]] = {
        var data: [String: [KrystalHistoryTransaction]] = [:]
        EtherscanTransactionStorage.shared.getKrystalTransaction().forEach { tx in
          var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
          trans.append(tx)
          data[self.dateFormatter.string(from: tx.date)] = trans
        }
        return data
      }()
      DispatchQueue.main.async {
        self.navigationController.hideLoading()
        self.rootViewController.coordinatorDidUpdateCompletedKrystalTransaction(sections: dates, data: sectionData)
      }
    }
  }

  func appCoordinatorPendingTransactionDidUpdate() {
    let pendingDates: [String] = {
      let dates = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().map { return self.dateFormatter.string(from: $0.time) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()
    
    let handledDates: [String] = {
      let dates = EtherscanTransactionStorage.shared.getHandledInternalHistoryTransactionForUnsupportedApi().map { return self.dateFormatter.string(from: $0.time) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [InternalHistoryTransaction]] = {
      var data: [String: [InternalHistoryTransaction]] = [:]
      EtherscanTransactionStorage.shared.getInternalHistoryTransaction().forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.time)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.time)] = trans
      }
      return data
    }()
    
    let sectionHandledData: [String: [InternalHistoryTransaction]] = {
      var data: [String: [InternalHistoryTransaction]] = [:]
      EtherscanTransactionStorage.shared.getHandledInternalHistoryTransactionForUnsupportedApi().forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.time)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.time)] = trans
      }
      return data
    }()

    self.rootViewController.coordinatorUpdatePendingTransaction(
      pendingData: sectionData,
      handledData: sectionHandledData,
      pendingDates: pendingDates,
      handledDates: handledDates
    )
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.hash, txHash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }

  fileprivate func openTransactionCancelConfirmPopUpFor(transaction: InternalHistoryTransaction) {
    
    let gasLimit: BigInt = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return BigInt(transaction.eip1559Transaction?.gasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
      } else {
        return BigInt(transaction.transactionObject?.gasLimit ?? "") ?? BigInt(0)
      }
    }()
    
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    
    viewModel.isCancelMode = true
    viewModel.transaction = transaction
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.navigationController.present(vc, animated: true, completion: nil)
    
    /*
    if KNGeneralProvider.shared.isUseEIP1559 {
      if let eipTx = transaction.eip1559Transaction,
         let gasLimitBigInt = BigInt(eipTx.gasLimit.drop0x, radix: 16),
         let maxPriorityBigInt = BigInt(eipTx.maxInclusionFeePerGas.drop0x, radix: 16),
         let maxGasFeeBigInt = BigInt(eipTx.maxGasFee.drop0x, radix: 16) {

        let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimitBigInt, selectType: .custom, currentRatePercentage: 0, isUseGasToken: false)
        viewModel.updateGasPrices(
          fast: KNGasCoordinator.shared.fastKNGas,
          medium: KNGasCoordinator.shared.standardKNGas,
          slow: KNGasCoordinator.shared.lowKNGas,
          superFast: KNGasCoordinator.shared.superFastKNGas
        )

        viewModel.advancedGasLimit = gasLimitBigInt.description
        viewModel.advancedMaxPriorityFee = maxPriorityBigInt.shortString(units: UnitConfiguration.gasPriceUnit)
        viewModel.advancedMaxFee = maxGasFeeBigInt.shortString(units: UnitConfiguration.gasPriceUnit)
        viewModel.isCancelMode = true
        viewModel.transaction = transaction
        let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
        vc.delegate = self
        self.navigationController.present(vc, animated: true, completion: nil)
      }
    } else {
      let viewModel = KNConfirmCancelTransactionViewModel(transaction: transaction)
      let confirmPopup = KNConfirmCancelTransactionPopUp(viewModel: viewModel)
      confirmPopup.delegate = self
      self.navigationController.present(confirmPopup, animated: true, completion: nil)
    }
    */
  }

  fileprivate func openTransactionSpeedUpViewController(transaction: InternalHistoryTransaction) {
    
    let gasLimit: BigInt = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return BigInt(transaction.eip1559Transaction?.reservedGasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
      } else {
        return BigInt(transaction.transactionObject?.reservedGasLimit ?? "") ?? BigInt(0)
      }
    }()
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )

    viewModel.transaction = transaction
    viewModel.isSpeedupMode = true
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.navigationController.present(vc, animated: true, completion: nil)
  }

  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent) {
    switch event {
    case .dismiss:
      self.stop()
    case .cancelTransaction(let transaction):
      guard KNGeneralProvider.shared.currentChain != .klaytn else {
        self.navigationController.showErrorTopBannerMessage(message: "Unsupported action")
        return
      }
      self.openTransactionCancelConfirmPopUpFor(transaction: transaction)
    case .speedUpTransaction(let transaction):
      guard KNGeneralProvider.shared.currentChain != .klaytn else {
        self.navigationController.showErrorTopBannerMessage(message: "Unsupported action")
        return
      }
      self.openTransactionSpeedUpViewController(transaction: transaction)
    case .quickTutorial(let pointsAndRadius):
      break
    case .openEtherScanWalletPage:
      let urlString = "\(self.etherScanURL)address/\(session.address.addressString)"
      self.rootViewController.openSafari(with: urlString)
    case .openKyberWalletPage:
    break
    case .selectPendingTransaction(transaction: let transaction):
      switch transaction.type {
      case .bridge:
        let module = TransactionDetailModule.build(internalTx: transaction)
        navigationController.pushViewController(module, animated: true)
      default:
        let coordinator = KNTransactionDetailsCoordinator(navigationController: self.navigationController, transaction: transaction)
        coordinator.start()
        self.txDetailsCoordinator = coordinator
      }
      
    case .selectCompletedTransaction(data: let data):
      let coordinator = KNTransactionDetailsCoordinator(navigationController: self.navigationController, data: data)
      coordinator.start()
      self.txDetailsCoordinator = coordinator
    case .selectCompletedKrystalTransaction(data: let data):
      let type = TransactionHistoryItemType(rawValue: data.historyItem.type) ?? .contractInteraction
      switch type {
      case .bridge:
        if data.isError {
          self.openEtherScanForTransaction(with: data.historyItem.txHash)
        } else {
          let module = TransactionDetailModule.build(tx: data.historyItem)
          navigationController.pushViewController(module, animated: true)
        }
      case .multiSend, .multiReceive:
        let module = TransactionDetailModule.build(tx: data.historyItem)
        navigationController.pushViewController(module, animated: true)
      default:
        let coordinator = KNTransactionDetailsCoordinator(navigationController: self.navigationController, data: data)
        coordinator.start()
        self.txDetailsCoordinator = coordinator
      }

    case .swap:
      if self.navigationController.tabBarController?.selectedIndex == 1 {
        self.navigationController.popToRootViewController(animated: true)
      } else {
        self.navigationController.tabBarController?.selectedIndex = 1
      }
    case .reloadAllData:
      self.session.transactionCoordinator?.loadEtherscanTransactions(isInit: true)
    }
  }

  fileprivate func openQuickTutorial(_ controller: KNHistoryViewController, pointsAndRadius: [(CGPoint, CGFloat)]) {
    let attributedString = NSMutableAttributedString(string: "Speed Up or Cancel transaction.".toBeLocalised(), attributes: [
      .font: UIFont.Kyber.regular(with: 18),
      .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
      .kern: 0.0,
    ])
    let contentTopOffset: CGFloat = 496.0
    let overlayer = controller.createOverlay(
      frame: controller.tabBarController!.view.frame,
      contentText: attributedString,
      contentTopOffset: contentTopOffset,
      pointsAndRadius: pointsAndRadius,
      nextButtonTitle: "Got it".toBeLocalised()
    )
    controller.tabBarController!.view.addSubview(overlayer)
  }
  
  func openMultichainTransaction(hash: String) {
    if let url = URL(string: Constants.multichainExplorerURL + "/tx/" + hash) {
      self.rootViewController.openSafari(with: url)
    }
  }

  fileprivate func openEtherScanForTransaction(with hash: String) {
    if let etherScanEndpoint = self.session.externalProvider?.customRPC.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.rootViewController.openSafari(with: url)
    }
  }
  
  fileprivate func openSendTokenView() {
    let from: TokenObject = KNGeneralProvider.shared.quoteTokenObject
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      balances: [:],
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }
}

extension KNHistoryCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    switch action {
    case .swap:
      if self.navigationController.tabBarController?.selectedIndex == 1 {
        self.navigationController.popToRootViewController(animated: true)
      } else {
        self.navigationController.tabBarController?.selectedIndex = 1
      }
    case .speedUp(tx: let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(tx: let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .openLink(url: let url):
      self.navigationController.openSafari(with: url)
    case .transfer:
      self.openSendTokenView()
    case .goToSupport:
      self.navigationController.openSafari(with: "https://docs.krystal.app/")
    default:
      break
    }
    self.transactionStatusVC = nil
  }
}

extension KNHistoryCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let url = WCURL(result) else {
        self.navigationController.showTopBannerView(
          with: Strings.invalidSession,
          message: Strings.invalidSessionTryOtherQR,
          time: 1.5
        )
        return
      }

      do {
        let privateKey = try WalletManager.shared.exportPrivateKey(address: AppDelegate.session.address)
        DispatchQueue.main.async {
          let controller = KNWalletConnectViewController(
            wcURL: url,
            pk: privateKey
          )
          self.navigationController.present(controller, animated: true, completion: nil)
        }
      } catch {
        self.navigationController.showTopBannerView(
          with: Strings.privateKeyError,
          message: Strings.canNotGetPrivateKey,
          time: 1.5
        )
      }
    }
  }
}

extension KNHistoryCoordinator: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.historyCoordinatorDidSelectAddToken(token)
  }
  
}

extension KNHistoryCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .helpPressed(let tag):
      var message = "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised()
      switch tag {
      case 1:
        message = KNGeneralProvider.shared.isUseEIP1559 ? "gas.limit.help".toBeLocalised() : "gas.limit.legacy.help".toBeLocalised()
      case 2:
        message = "max.priority.fee.help".toBeLocalised()
      case 3:
        message = KNGeneralProvider.shared.isUseEIP1559 ? "max.fee.help".toBeLocalised() : "gas.price.legacy.help".toBeLocalised()
      case 4:
        message = "nonce.help".toBeLocalised()
      default:
        break
      }
      self.navigationController.showBottomBannerView(
        message: message,
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .speedupTransactionSuccessfully(let speedupTransaction):
      self.openTransactionStatusPopUp(transaction: speedupTransaction)
    case .cancelTransactionSuccessfully(let cancelTransaction):
      self.openTransactionStatusPopUp(transaction: cancelTransaction)
    case .speedupTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    case .cancelTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    default:
      break
    }
  }
}
