// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import BigInt
import TrustCore
import Moya
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnectSwift

protocol KNHistoryCoordinatorDelegate: class {
  func historyCoordinatorDidClose()
  func historyCoordinatorDidSelectWallet(_ wallet: Wallet)
  func historyCoordinatorDidSelectManageWallet()
  func historyCoordinatorDidSelectAddWallet()
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject)
  func historyCoordinatorDidSelectAddChainWallet(chainType: ChainType)
}

class KNHistoryCoordinator: NSObject, Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  let navigationController: UINavigationController
  private(set) var session: KNSession

  var currentWallet: KNWalletObject
  var sendCoordinator: KNSendTokenViewCoordinator?

  var coordinators: [Coordinator] = []
  weak var delegate: KNHistoryCoordinatorDelegate?
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  var etherScanURL: String {
    return KNGeneralProvider.shared.customRPC.etherScanEndpoint
  }

  lazy var rootViewController: KNHistoryViewController = {
    let viewModel = KNHistoryViewModel(
      currentWallet: self.currentWallet
    )
    let controller = KNHistoryViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  var txDetailsCoordinator: KNTransactionDetailsCoordinator?

  var speedUpViewController: SpeedUpCustomGasSelectViewController?

  init(
    navigationController: UINavigationController,
    session: KNSession
  ) {
    self.navigationController = navigationController
    self.session = session
    let address = self.session.wallet.addressString
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true) {
      self.appCoordinatorTokensTransactionsDidUpdate(showLoading: true)
      self.appCoordinatorPendingTransactionDidUpdate()
      self.rootViewController.coordinatorUpdateTokens()
      if KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        self.session.transacionCoordinator?.loadEtherscanTransactions()
      }
    }
  }

  func stop() {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.historyCoordinatorDidClose()
    }
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    let address = self.session.wallet.addressString
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    self.appCoordinatorTokensTransactionsDidUpdate()
    self.rootViewController.coordinatorUpdateTokens()
    self.appCoordinatorPendingTransactionDidUpdate()
    self.rootViewController.coordinatorUpdateNewSession(wallet: self.currentWallet)
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.rootViewController.coordinatorUpdateWalletObjects()
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
    handledDates: handledDates,
    currentWallet: self.currentWallet )
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func coordinatorGasPriceCachedDidUpdate() {
    speedUpViewController?.updateGasPriceUIs()
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

    viewModel.isSpeedupMode = true
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
        viewModel.isSpeedupMode = true
        viewModel.transaction = transaction
        let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
        vc.delegate = self
        self.navigationController.present(vc, animated: true, completion: nil)
      }
    } else {
      let viewModel = SpeedUpCustomGasSelectViewModel(transaction: transaction)
      let controller = SpeedUpCustomGasSelectViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      navigationController.present(controller, animated: true, completion: nil)
      speedUpViewController = controller
    }
    */
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
      let urlString = "\(self.etherScanURL)address/\(self.session.wallet.addressString)"
      self.rootViewController.openSafari(with: urlString)
    case .openKyberWalletPage:
    break
    case .openWalletsListPopup:
      let viewModel = WalletsListViewModel(
        walletObjects: KNWalletStorage.shared.availableWalletObjects,
        currentWallet: self.currentWallet
      )
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
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
      self.session.transacionCoordinator?.loadEtherscanTransactions(isInit: true)
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
      session: self.session,
      balances: [:],
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }
}

extension KNHistoryCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction) {
    if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
      let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)

      if let cancelTx = transaction.transactionObject?.toCancelTransaction(account: account) {
        saved?.state = .cancel
        saved?.type = .transferETH
        saved?.transactionSuccessDescription = "-0 ETH"
        cancelTx.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            saved?.hash = hash
            if let unwrapped = saved {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        }
      }

      if let cancelTx = transaction.eip1559Transaction?.toCancelTransaction(), let data = provider.signContractGenericEIP1559Transaction(cancelTx) {
        saved?.state = .cancel
        saved?.type = .transferETH
        saved?.transactionSuccessDescription = "-0 ETH"
        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
          switch sendResult {
          case .success(let hash):
            saved?.hash = hash
            if let unwrapped = saved {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        })
      }
    } else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
    }
  }
}

extension KNHistoryCoordinator: SpeedUpCustomGasSelectDelegate {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent) {
    switch event {
    case .done(let transaction, let newValue):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
        savedTx?.state = .speedup
        let speedupTx = transaction.transactionObject?.toSpeedupTransaction(account: account, gasPrice: newValue) //TODO: add case eip1559
        speedupTx?.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            savedTx?.hash = hash
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
            
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        }
      } else {
        self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
      }
    case .invaild:
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "your.gas.must.be.10.percent.higher".toBeLocalised(),
        time: 1.5
      )
    }
    speedUpViewController = nil
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

extension KNHistoryCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.historyCoordinatorDidSelectManageWallet()
    case .copy(let wallet):
      UIPasteboard.general.string = wallet.address
      let hud = MBProgressHUD.showAdded(to: controller.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    case .select(let wallet):
      guard let wal = self.session.keystore.matchWithWalletObject(wallet, chainType: KNGeneralProvider.shared.currentChain == .solana ? .solana : .multiChain) else {
        return
      }
      self.delegate?.historyCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.historyCoordinatorDidSelectAddWallet()
    }
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

extension KNHistoryCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.historyCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
  
  func sendTokenCoordinatorDidClose() {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.historyCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.historyCoordinatorDidSelectWallet(wallet)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.navigationController.popViewController(animated: true)
  }
  
  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.historyCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.historyCoordinatorDidSelectAddWallet()
  }
}

extension KNHistoryCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
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
    case .speedupTransaction(transaction: let transaction, original: let original):
      if let data = self.session.externalProvider?.signContractGenericEIP1559Transaction(transaction) {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
          switch sendResult {
          case .success(let hash):
            savedTx?.state = .speedup
            savedTx?.hash = hash
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        })
      }
    case .cancelTransaction(transaction: let transaction, original: let original):
      if let data = self.session.externalProvider?.signContractGenericEIP1559Transaction(transaction) {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
          switch sendResult {
          case .success(let hash):
            savedTx?.state = .cancel
            savedTx?.type = .transferETH
            savedTx?.transactionSuccessDescription = "-0 ETH"
            savedTx?.hash = hash
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        })
      }
    case .speedupTransactionLegacy(legacyTransaction: let transaction, original: let original):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
        let speedupTx = transaction.toSignTransaction(account: account)
        speedupTx.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            savedTx?.state = .speedup
            savedTx?.hash = hash
            print("GasSelector][Legacy][Speedup][Sent] \(hash)")
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        }
      }
    case .cancelTransactionLegacy(legacyTransaction: let transaction, original: let original):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
        let cancelTx = transaction.toSignTransaction(account: account)
        cancelTx.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            saved?.state = .cancel
            saved?.type = .transferETH
            saved?.transactionSuccessDescription = "-0 ETH"
            saved?.hash = hash
            print("GasSelector][Legacy][Cancel][Sent] \(hash)")
            if let unwrapped = saved {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        }
      }
    default:
      break
    }
  }
}
