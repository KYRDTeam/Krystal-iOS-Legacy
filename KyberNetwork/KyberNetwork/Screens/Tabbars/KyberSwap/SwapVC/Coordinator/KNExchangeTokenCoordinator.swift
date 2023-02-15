// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import Result
import Moya
import APIKit
import QRCodeReaderViewController
import MBProgressHUD
import JSONRPCKit
import WalletConnectSwift
import MBProgressHUD
import KrystalWallets
import Dependencies

protocol KNExchangeTokenCoordinatorDelegate: class {
  func exchangeTokenCoordinator(didAdd wallet: KWallet, chain: ChainType)
  func exchangeTokenCoordinator(didAdd watchAddress: KAddress, chain: ChainType)
  func exchangeTokenCoordinatorDidSelectAddChainWallet(chainType: ChainType)
  func exchangeTokenCoordinatorRemoveWallet(_ wallet: KWallet)
  func exchangeTokenCoordinatorDidSelectAddWallet()
  func exchangeTokenCoordinatorDidSelectPromoCode()
  func exchangeTokenCoordinatorOpenManageOrder()
  func exchangeTokenCoordinatorDidSelectManageWallet()
  func exchangeTokenCoodinatorDidSendRefCode(_ code: String)
  func exchangeTokenCoordinatorDidSelectAddToken(_ token: TokenObject)
  func exchangeTokenCoordinatorDidAddTokens(srcToken: TokenObject?, destToken: TokenObject?)
  func exchangeTokenCoordinatorDidSelectTokens(token: Token)
}

//swiftlint:disable file_length
class KNExchangeTokenCoordinator: NSObject, Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  
  var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  var isSelectingSourceToken: Bool = true
  /// src and dest token used for deeplink
  var srcTokenAddress, destTokenAddress: String?
  var priceImpactSource: [String] = []
  fileprivate var balances: [String: Balance] = [:]
  weak var delegate: KNExchangeTokenCoordinatorDelegate?

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
  fileprivate var confirmSwapVC: KConfirmSwapViewController?
  fileprivate weak var transactionStatusVC: SwapProcessPopup?
  fileprivate var gasFeeSelectorVC: GasFeeSelectorPopupViewController?

  lazy var rootViewController: KSwapViewController = {
    let (from, to): (TokenObject, TokenObject) = {
      let address = AppDelegate.session.address.addressString
      let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: address)
      return (KNSupportedTokenStorage.shared.ethToken, KNSupportedTokenStorage.shared.kncToken)
    }()
    let viewModel = KSwapViewModel(
      from: from,
      to: to,
      supportedTokens: tokens
    )
    let controller = KSwapViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var promoCodeCoordinator: KNPromoCodeCoordinator?

  fileprivate var qrcodeCoordinator: KNWalletQRCodeCoordinator? {
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(
      navigationController: self.navigationController
    )
    return qrcodeCoordinator
  }

  fileprivate var historyCoordinator: KNHistoryCoordinator?
  fileprivate var searchTokensViewController: KNSearchTokenViewController?

  deinit {
    self.stop()
  }
  
  var session: KNSession {
    return AppDelegate.session
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.observeAppEvents()
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: false)
    self.sendTokenCoordinator = nil
    self.confirmSwapVC = nil
    self.promoCodeCoordinator = nil
    self.historyCoordinator = nil
    self.searchTokensViewController = nil
    self.removeObservers()
  }
  
  func removeObservers() {
    NotificationCenter.default.removeObserver(
      self,
      name: AppEventCenter.shared.kAppDidChangeAddress,
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
  }
  
}

// MARK: Update from app coordinator
extension KNExchangeTokenCoordinator {
  
  @objc func appDidSwitchAddress() {
    rootViewController.coordinatorAppDidUpdateAddress()
    navigationController.popToRootViewController(animated: false)
    self.balances = [:]
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalance(otherTokensBalance)
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.searchTokensViewController?.updateBalances(otherTokensBalance)
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    self.rootViewController.coordinatorTrackerRateDidUpdate()
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
  }
  
  func appCoordinatorReceivedTokensSwapFromUniversalLink(srcTokenAddress: String?, destTokenAddress: String?, chainIdString: String?) {
    // default swap screen
    self.navigationController.tabBarController?.selectedIndex = 1
    self.navigationController.popToRootViewController(animated: false)
    guard let chainIdString = chainIdString else {
      return
    }

    let chainId = Int(chainIdString) ?? AllChains.ethMainnetPRC.chainID
    //switch chain if need
    if KNGeneralProvider.shared.customRPC.chainID != chainId {
      self.rootViewController.coordinatorShouldShowSwitchChainPopup(chainId: chainId)
      self.srcTokenAddress = srcTokenAddress
      self.destTokenAddress = destTokenAddress
    } else {
      self.prepareTokensForSwap(srcTokenAddress: srcTokenAddress, destTokenAddress: destTokenAddress, chainId: chainId, isFromDeepLink: true)
    }
  }

  func prepareTokensForSwap(srcTokenAddress: String?, destTokenAddress: String?, chainId: Int, isFromDeepLink: Bool = false) {
    // default token
    var fromToken = KNGeneralProvider.shared.currentChain.quoteTokenObject()
    var toToken = KNGeneralProvider.shared.currentChain.defaultToSwapToken()

    var newAddress: [String] = []
    guard let srcTokenAddress = srcTokenAddress, let destTokenAddress = destTokenAddress else {
      self.rootViewController.coordinatorUpdateTokens(fromToken: fromToken, toToken: toToken)
      return
    }

    let isValidSrcAddress = KNGeneralProvider.shared.isAddressValid(address: srcTokenAddress)
    let isValidDestTokenAddress = KNGeneralProvider.shared.isAddressValid(address: destTokenAddress)
    
    guard isValidSrcAddress, isValidDestTokenAddress else {
      self.rootViewController.coordinatorUpdateTokens(fromToken: fromToken, toToken: toToken)
      return
    }
    // in case can get token with given address
    if let token = KNSupportedTokenStorage.shared.get(forPrimaryKey: srcTokenAddress) {
       fromToken = token
    } else {
       newAddress.append(srcTokenAddress)
    }

    if let token = KNSupportedTokenStorage.shared.get(forPrimaryKey: destTokenAddress) {
      toToken = token
    } else {
      newAddress.append(destTokenAddress)
    }

    if newAddress.isEmpty {
      // there are no new address then show swap screen
      self.rootViewController.coordinatorUpdateTokens(fromToken: fromToken, toToken: toToken)
    } else if isFromDeepLink {
      // if there is any new address then show add token screen
      self.requestTokenInfoIfNeeded(srcAddress: srcTokenAddress, destAddress: destTokenAddress)
    }
  }
  
  func requestTokenInfoIfNeeded(srcAddress: String?, destAddress: String?) {
    var srcToken: TokenObject?
    var destToken: TokenObject?
    var getTokenFail = false
    let group = DispatchGroup()
    self.rootViewController.showLoadingHUD()
    if let srcAddress = srcAddress {
      group.enter()
      self.requestInfo(address: srcAddress) { token, success in
        if success {
          srcToken = token
        } else {
          getTokenFail = true
        }
        group.leave()
      }
    }

    if let destAddress = destAddress {
      group.enter()
      self.requestInfo(address: destAddress) { token, success in
        if success {
          destToken = token
        } else {
          getTokenFail = true
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      if !getTokenFail {
        self.delegate?.exchangeTokenCoordinatorDidAddTokens(srcToken: srcToken, destToken: destToken)
      }
    }
  }

  func requestInfo(address: String, complete: @escaping (TokenObject, Bool) -> Void) {
    var tokenSymbol = ""
    var tokenDecimal = ""
    let group = DispatchGroup()
    var getTokenFail = false
    group.enter()
    KNGeneralProvider.shared.getTokenSymbol(address: address) { (result) in
      switch result {
      case .success(let symbol):
        tokenSymbol = symbol
      case .failure(let error):
        getTokenFail = true
        print("[Custom token][Errror] \(error.description)")
      }
      group.leave()
    }
    group.enter()
    KNGeneralProvider.shared.getTokenDecimals(address: address) { (result) in
      switch result {
      case .success(let decimals):
        tokenDecimal = decimals
      case .failure(let error):
        getTokenFail = true
        print("[Custom token][Errror] \(error.description)")
      }
      group.leave()
    }

    group.notify(queue: .main) {
      let tokenObj = TokenObject(name: "", symbol: tokenSymbol, address: address, decimals: Int(tokenDecimal) ?? 18, logo: "")
      if getTokenFail {
        complete(TokenObject(), false)
      } else {
        complete(tokenObj, true)
      }
    }
  }

  func appCoordinatorShouldOpenExchangeForToken(_ token: TokenObject, isReceived: Bool = false) {
    self.navigationController.popToRootViewController(animated: true)
    self.rootViewController.coordinatorUpdateSelectedToken(token, isSource: !isReceived, isWarningShown: false)
    let selectToken = KNGeneralProvider.shared.currentChain.otherTokenObject(toToken: token)
    self.rootViewController.coordinatorUpdateSelectedToken(selectToken, isSource: isReceived, isWarningShown: true)
    self.rootViewController.tabBarController?.selectedIndex = 1
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    let supportedTokens = KNSupportedTokenStorage.shared.supportedTokens
    self.tokens = supportedTokens
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.searchTokensViewController?.updateListSupportedTokens(supportedTokens)
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorPendingTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate()
    self.rootViewController.coordinatorDidUpdatePendingTx()
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.rootViewController.coordinatorUpdateGasPriceCached()
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.gasFeeSelectorVC?.coordinatorDidUpdateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorPushNotificationOpenSwap(from: String, to: String) {
    guard let from = self.session.tokenStorage.tokens.first(where: { return $0.symbol == from }),
      let to = self.session.tokenStorage.tokens.first(where: { return $0.symbol == to }) else { return }
    self.navigationController.popToRootViewController(animated: false)
    self.rootViewController.coordinatorUpdateSelectedToken(from, isSource: true, isWarningShown: false)
    self.rootViewController.coordinatorUpdateSelectedToken(to, isSource: false)
  }

  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.historyCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if let trans = self.transactionStatusVC?.transaction, trans.hash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx) ?? false
  }

  func appCoordinatorDidUpdateChain() {
    self.rootViewController.coordinatorDidUpdateChain()
    if self.srcTokenAddress != nil || self.destTokenAddress != nil {
      let isFromDeepLink = self.rootViewController.viewModel.isFromDeepLink
      self.prepareTokensForSwap(srcTokenAddress: self.srcTokenAddress, destTokenAddress: self.destTokenAddress, chainId: KNGeneralProvider.shared.customRPC.chainID, isFromDeepLink: isFromDeepLink)
      self.srcTokenAddress = nil
      self.destTokenAddress = nil
    }
  }
}

// MARK: Network requests
extension KNExchangeTokenCoordinator {
  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = SwapProcessPopup(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }

  //TODO: remove later
  fileprivate func resetAllowanceForExchangeTransactionIfNeeded(_ exchangeTransaction: KNDraftExchangeTransaction, remain: BigInt, gasLimit: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    if remain.isZero {
      completion(.success(true))
      return
    }
    let gasPrice = exchangeTransaction.gasPrice ?? KNGasCoordinator.shared.defaultKNGas
    provider.sendApproveERCToken(
      address: currentAddress,
      for: exchangeTransaction.from,
      value: BigInt(0),
      gasPrice: gasPrice,
      gasLimit: gasLimit
    ) { result in
      switch result {
      case .success:
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func resetAllowanceForTokenIfNeeded(_ token: TokenObject, remain: BigInt, gasLimit: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    if remain.isZero {
      completion(.success(true))
      return
    }
    let gasPrice = KNGasCoordinator.shared.defaultKNGas
    provider.sendApproveERCToken(
      address: currentAddress,
      for: token,
      value: BigInt(0),
      gasPrice: gasPrice,
      gasLimit: gasLimit
    ) { result in
      switch result {
      case .success:
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: Confirm transaction
extension KNExchangeTokenCoordinator: KConfirmSwapViewControllerDelegate {
  func kConfirmSwapViewControllerOpenGasPriceSelect() {
    self.rootViewController.coordinatorEditTransactionSetting()
  }
  
  func kConfirmSwapViewController(_ controller: KConfirmSwapViewController, confirm data: KNDraftExchangeTransaction, eip1559Tx: EIP1559Transaction, internalHistoryTransaction: InternalHistoryTransaction) {
    print("[EIP1559] send confirm \(eip1559Tx)")
    guard let provider = self.session.externalProvider else {
      return
    }
    guard let data = EIP1559TransactionSigner().signTransaction(address: currentAddress, eip1559Tx: eip1559Tx) else {
      return
    }
    self.navigationController.displayLoading()
    KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
      self.navigationController.hideLoading()
      switch sendResult {
      case .success(let hash):
        provider.minTxCount += 1

        internalHistoryTransaction.hash = hash
        internalHistoryTransaction.nonce = Int(eip1559Tx.nonce, radix: 16) ?? 0
        internalHistoryTransaction.time = Date()

        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalHistoryTransaction)
        controller.dismiss(animated: true) {
          self.confirmSwapVC = nil
          self.openTransactionStatusPopUp(transaction: internalHistoryTransaction)
        }
        self.rootViewController.coordinatorSuccessSendTransaction()
      case .failure(let error):
        var errorMessage = error.description
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
            errorMessage = message
          }
        }
        self.navigationController.showErrorTopBannerMessage(
          with: "Error",
          message: errorMessage,
          time: 1.5
        )
      }
    })
  }

  func kConfirmSwapViewController(_ controller: KConfirmSwapViewController, confirm data: KNDraftExchangeTransaction, signTransaction: SignTransaction, internalHistoryTransaction: InternalHistoryTransaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    self.navigationController.displayLoading()
    let signResult = EthereumTransactionSigner().signTransaction(address: currentAddress, transaction: signTransaction)
    switch signResult {
    case .success(let signedData):
      KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
        self.navigationController.hideLoading()
        switch sendResult {
        case .success(let hash):
          provider.minTxCount += 1
          internalHistoryTransaction.hash = hash
          internalHistoryTransaction.nonce = signTransaction.nonce
          internalHistoryTransaction.time = Date()
          
          EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalHistoryTransaction)
          controller.dismiss(animated: true) {
            self.confirmSwapVC = nil
            self.openTransactionStatusPopUp(transaction: internalHistoryTransaction)
          }
          self.rootViewController.coordinatorSuccessSendTransaction()
        case .failure(let error):
          var errorMessage = error.description
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = message
            }
          }
          self.navigationController.showErrorTopBannerMessage(
            with: "Error",
            message: errorMessage
          )
        }
      })
    case .failure:
      self.rootViewController.coordinatorFailSendTransaction()
    }
  }

  func kConfirmSwapViewControllerDidCancel(_ controller: KConfirmSwapViewController) {
    controller.dismiss(animated: true) {
      self.confirmSwapVC = nil
    }
  }
}

// MARK: Swap view delegation
extension KNExchangeTokenCoordinator: KSwapViewControllerDelegate {
  func kSwapViewController(_ controller: KSwapViewController, run event: KSwapViewEvent) {
    switch event {
    case .searchToken(let from, let to, let isSource):
      self.openSearchToken(from: from, to: to, isSource: isSource)
    case .getGasLimit(let from, let to, let amount, let raw):
      self.getGasLimit(from: from, to: to, amount: amount, tx: raw)
    case .showQRCode:
      self.showWalletQRCode()
    case .confirmSwap(let data, let tx, let priceImpact, let platform, let rawTransaction, let minReceivedData, maxSlippage: let maxSlippage):
      self.navigationController.displayLoading()
      KNGeneralProvider.shared.getEstimateGasLimit(transaction: tx) { (result) in
        self.navigationController.hideLoading()
        switch result {
        case .success:
            self.showConfirmSwapScreen(data: data, transaction: tx, eip1559: nil, priceImpact: priceImpact, platform: platform, rawTransaction: rawTransaction, minReceiveAmount: minReceivedData.1 ?? "", minReceiveTitle: minReceivedData.0 ?? "", maxSlippage: maxSlippage)
        case .failure(let error):
          var errorMessage = "Can not estimate Gas Limit"
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
            }
          }
          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
          }
          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
          }
          self.navigationController.showErrorTopBannerMessage(message: errorMessage)
        }
      }
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let type, let percent, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      let vm = TransactionSettingsViewModel(gasLimit: gasLimit, rate: nil, defaultOpenAdvancedMode: false)
      let popup = TransactionSettingsViewController(viewModel: vm)
      vm.update(priorityFee: advancedPriorityFee, maxGas: advancedMaxFee, gasLimit: advancedGasLimit, nonceString: advancedNonce)
      
      popup.delegate = self
      self.navigationController.pushViewController(popup, animated: true, completion: nil)

    case .updateRate(let rate):
      self.gasFeeSelectorVC?.coordinatorDidUpdateMinRate(rate)
    case .openHistory:
      self.openHistoryScreen()
    case .openWalletsList:
      let viewModel = WalletsListViewModel()
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
    case .getAllRates(let from, let to, let srcAmount, let focusSrc):
      self.getAllRates(from: from, to: to, amount: srcAmount, focusSrc: focusSrc)
    case .openChooseRate(let from, let to, let rates, let gasPrice, let amountFrom):
        let viewModel = ChooseRateViewModel(from: from, to: to, data: rates, gasPrice: gasPrice, amountFrom: amountFrom)
      let vc = ChooseRateViewController(viewModel: viewModel)
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    case .checkAllowance(let from):
      guard let provider = AppDelegate.session.externalProvider else {
        return
      }
      provider.getAllowance(token: from) { [weak self] getAllowanceResult in
        guard let `self` = self else { return }
        switch getAllowanceResult {
        case .success(let res):
          self.rootViewController.coordinatorDidUpdateAllowance(token: from, allowance: res)
        case .failure:
          self.rootViewController.coordinatorDidFailUpdateAllowance(token: from)
        }
      }
    case .sendApprove(let token, let remain):
      let vc = ApproveTokenViewController(viewModel: ApproveTokenViewModelForTokenObject(token: token, res: remain))
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    case .getExpectedRate(let from, let to, let srcAmount, let hint):
      if currentAddress.isWatchWallet {
        self.navigationController.showTopBannerView(message: Strings.watchWalletCannotDoThisOperation)
        self.navigationController.hideLoading()
        return
      }
      self.getExpectedRate(from: from, to: to, srcAmount: srcAmount, hint: hint)
    case .getLatestNonce:
      self.getLatestNonce { [weak self] result in
        guard let `self` = self else { return }
        self.navigationController.hideLoading()
        switch result {
        case .success(let res):
          self.rootViewController.coordinatorSuccessUpdateLatestNonce(nonce: res)
        case .failure:
          self.rootViewController.coordinatorFailUpdateLatestNonce()
        }
      }
    case .buildTx(let raw):
      self.getEncodedSwapTransaction(raw)
    case .signAndSendTx(let tx):
      guard let provider = self.session.externalProvider else {
        return
      }
      let signResult = EthereumTransactionSigner().signTransaction(address: currentAddress, transaction: tx)
      switch signResult {
      case .success(let data):
        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
          switch sendResult {
          case .success:
            provider.minTxCount += 1
            self.rootViewController.coordinatorSuccessSendTransaction()
          case .failure(let error):
            print("[Debug] error send \(error)")
            self.rootViewController.coordinatorFailSendTransaction()
          }
        })
      case .failure:
        self.rootViewController.coordinatorFailSendTransaction()
      }
    case .getRefPrice(let from, let to):
      self.getRefPrice(from: from, to: to)
    case .confirmEIP1559Swap(data: let data, eip1559tx: let tx, priceImpact: let priceImpact, platform: let platform, rawTransaction: let rawTransaction, minReceiveDest: let minReceivedData, maxSlippage: let maxSlippage):
      self.navigationController.displayLoading()
      KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: tx) { (result) in
        self.navigationController.hideLoading()
        switch result {
        case .success:
          print("[EIP1559] success est gas")
          self.showConfirmSwapScreen(data: data, transaction: nil, eip1559: tx, priceImpact: priceImpact, platform: platform, rawTransaction: rawTransaction, minReceiveAmount: minReceivedData.1 ?? "", minReceiveTitle: minReceivedData.0 ?? "", maxSlippage: maxSlippage)
        case .failure(let error):
          var errorMessage = "Can not estimate Gas Limit"
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
            }
          }
          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
          }
          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
          }
          self.navigationController.showErrorTopBannerMessage(message: errorMessage)
        }
      }
    case .addChainWallet(let chainType):
      delegate?.exchangeTokenCoordinatorDidSelectAddChainWallet(chainType: chainType)
    }
  }

  fileprivate func openSearchToken(from: TokenObject?, to: TokenObject?, isSource: Bool) {
    if let topVC = self.navigationController.topViewController, topVC is KNSearchTokenViewController { return }
    self.isSelectingSourceToken = isSource
    self.tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
    self.searchTokensViewController = {
      let viewModel = KNSearchTokenViewModel(
        supportedTokens: self.tokens
      )
      let controller = KNSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.present(self.searchTokensViewController!, animated: true, completion: nil)
    self.searchTokensViewController?.updateBalances(self.balances)
  }

  fileprivate func showConfirmSwapScreen(data: KNDraftExchangeTransaction, transaction: SignTransaction?, eip1559: EIP1559Transaction?, priceImpact: Double, platform: String, rawTransaction: TxObject, minReceiveAmount: String, minReceiveTitle: String, maxSlippage: Double) {
    self.confirmSwapVC = {
      let ethBal = self.balances[KNSupportedTokenStorage.shared.ethToken.contract]?.value ?? BigInt(0)
      let viewModel = KConfirmSwapViewModel(transaction: data, ethBalance: ethBal, signTransaction: transaction, eip1559Tx: eip1559, priceImpact: priceImpact, priceImpactSource: self.priceImpactSource, platform: platform, rawTransaction: rawTransaction, minReceiveAmount: minReceiveAmount, minReceiveTitle: minReceiveTitle, maxSlippage: maxSlippage)
      let controller = KConfirmSwapViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.present(self.confirmSwapVC!, animated: true, completion: nil)
  }

  fileprivate func getExpectedExchangeRate(from: TokenObject, to: TokenObject, amount: BigInt, hint: String = "", withKyber: Bool = false, completion: ((Result<(BigInt, BigInt), AnyError>) -> Void)? = nil) {
    guard let provider = self.session.externalProvider else {
      return
    }
    if from == to {
      let rate = BigInt(10).power(from.decimals)
      let slippageRate = rate * BigInt(97) / BigInt(100)
      completion?(.success((rate, slippageRate)))
      return
    }
    provider.getExpectedRate(
      from: from,
      to: to,
      amount: amount,
      hint: hint,
      withKyber: withKyber
    ) { (result) in
        var estRate: BigInt = BigInt(0)
        var slippageRate: BigInt = BigInt(0)
        switch result {
        case .success(let data):
          estRate = data.0
          slippageRate = data.1
          estRate /= BigInt(10).power(18 - to.decimals)
          slippageRate /= BigInt(10).power(18 - to.decimals)
          completion?(.success((estRate, slippageRate)))
        case .failure(let error):
          completion?(.failure(error))
        }
    }
  }

  func getAllRates(from: TokenObject, to: TokenObject, amount: BigInt, focusSrc: Bool) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let src = from.contract.lowercased()
    let dest = to.contract.lowercased()
    let amt = amount.isZero ? from.placeholderValue.description : amount.description
    let address = currentAddress.addressString
    provider.requestWithFilter(.getAllRates(src: src, dst: dest, amount: amt, focusSrc: focusSrc, userAddress: address)) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let resp) = result {
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(RateResponse.self, from: resp.data)
          let sortedRate = data.rates.sorted { rate1, rate2 in
            return BigInt.bigIntFromString(value: rate1.rate)  > BigInt.bigIntFromString(value: rate2.rate)
          }
          self.rootViewController.coordinatorDidUpdateRates(from: from, to: to, srcAmount: amount, rates: sortedRate)
        } catch {
          self.rootViewController.coordinatorFailUpdateRates()
        }
      } else {
        self.rootViewController.coordinatorFailUpdateRates()
      }
    }
  }

  func getExpectedRate(from: TokenObject, to: TokenObject, srcAmount: BigInt, hint: String) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let src = from.contract.lowercased()
    let dest = to.contract.lowercased()
    let amt = srcAmount.isZero ? from.placeholderValue.description : srcAmount.description
    self.navigationController.displayLoading()
    provider.requestWithFilter(.getExpectedRate(src: src, dst: dest, srcAmount: amt, hint: hint, isCaching: true)) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let rate = json["rate"] as? String, let rateBigInt = BigInt(rate) {
        self.rootViewController.coordinatorDidUpdateExpectedRate(from: from, to: to, amount: srcAmount, rate: rateBigInt)
      } else {
        self.rootViewController.coordinatorDidUpdateExpectedRate(from: from, to: to, amount: srcAmount, rate: BigInt(0))
      }
    }
  }

  func getEncodedSwapTransaction(_ tx: RawSwapTransaction) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    self.navigationController.displayLoading()
    provider.requestWithFilter(.buildSwapTx(address: tx.userAddress, src: tx.src, dst: tx.dest, srcAmount: tx.srcQty, minDstAmount: tx.minDesQty, gasPrice: tx.gasPrice, nonce: tx.nonce, hint: tx.hint, useGasToken: tx.useGasToken)) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      if case .success(let resp) = result {
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(TransactionResponse.self, from: resp.data)
          self.rootViewController.coordinatorSuccessUpdateEncodedTx(object: data.txObject)
        } catch {
          self.rootViewController.coordinatorFailUpdateEncodedTx()
        }
      } else {
        self.rootViewController.coordinatorFailUpdateEncodedTx()
      }
    }
  }

  func getGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, tx: RawSwapTransaction) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.requestWithFilter(.buildSwapTx(address: tx.userAddress, src: tx.src, dst: tx.dest, srcAmount: tx.srcQty, minDstAmount: tx.minDesQty, gasPrice: tx.gasPrice, nonce: 1, hint: tx.hint, useGasToken: tx.useGasToken)) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let resp) = result {
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(TransactionResponse.self, from: resp.data)
          if let gasLimit = BigInt(data.txObject.gasLimit.drop0x, radix: 16) {
            self.rootViewController.coordinatorDidUpdateGasLimit(
              from: from,
              to: to,
              amount: amount,
              gasLimit: gasLimit
            )
            self.gasFeeSelectorVC?.coordinatorDidUpdateGasLimit(gasLimit)
            print("[Swap][GasLimit][Success] \(gasLimit.description)")
          }
        } catch let error {
          print("[Swap][GasLimit][Error] \(error.localizedDescription)")
        }
      } else {
        print("[Swap][GasLimit][Error] unknow")
      }
    }
  }

  func getGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, hint: String) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let src = from.contract.lowercased()
    let dest = to.contract.lowercased()
    let amt = amount.isZero ? from.placeholderValue.description : amount.description
    provider.requestWithFilter(.getGasLimit(src: src, dst: dest, srcAmount: amt, hint: hint)) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let gasLimitString = json["gasLimit"] as? String, let gasLimit = BigInt(gasLimitString.drop0x, radix: 16) {
        self.rootViewController.coordinatorDidUpdateGasLimit(
          from: from,
          to: to,
          amount: amount,
          gasLimit: gasLimit
        )
        self.gasFeeSelectorVC?.coordinatorDidUpdateGasLimit(gasLimit)
      } else {
        //TODO: add handle for fail load gas limit
      }
    }
  }

  func getRefPrice(from: TokenObject, to: TokenObject) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let src = from.contract.lowercased()
    let dest = to.contract.lowercased()
    provider.requestWithFilter(.getRefPrice(src: src, dst: dest)) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let change = json["refPrice"] as? String, let sources = json["sources"] as? [String] {
        self.priceImpactSource = sources
        self.rootViewController.coordinatorSuccessUpdateRefPrice(from: from, to: to, change: change, source: sources)
      } else {
        //TODO: add handle for fail load ref price
      }
    }
  }

  func updateEstimatedGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, gasPrice: BigInt, hint: String, completion: @escaping () -> Void = {}) {
    guard let provider = self.session.externalProvider else {
      return
    }
    let exchangeTx = KNDraftExchangeTransaction(
      from: from,
      to: to,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: BigInt(0),
      minRate: .none,
      gasPrice: gasPrice,
      gasLimit: .none,
      expectedReceivedString: nil,
      hint: hint
    )
    provider.getEstimateGasLimit(address: currentAddress, for: exchangeTx) { result in
      if case .success(let estimate) = result {
        self.rootViewController.coordinatorDidUpdateGasLimit(
          from: from,
          to: to,
          amount: amount,
          gasLimit: estimate
        )
        self.gasFeeSelectorVC?.coordinatorDidUpdateGasLimit(estimate)
      }
    }
  }

  fileprivate func showWalletQRCode() {
    self.qrcodeCoordinator?.start()
  }

  fileprivate func openSendTokenView() {
    let from: TokenObject = KNGeneralProvider.shared.quoteTokenObject
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      balances: self.balances,
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendTokenCoordinator = coordinator
  }

  fileprivate func openPromoCodeView() {
    self.delegate?.exchangeTokenCoordinatorDidSelectPromoCode()
  }

  fileprivate func openAddWalletView() {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddWallet()
  }
  
  fileprivate func openHistoryScreen() {
      AppDependencies.router.openTransactionHistory()
  }

  fileprivate func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getTransactionCount { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: Search token
extension KNExchangeTokenCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true) {
      self.searchTokensViewController = nil
      if case .select(let token) = event {
        self.rootViewController.coordinatorUpdateSelectedToken(
          token,
          isSource: self.isSelectingSourceToken
        )
      } else if case .add(let token) = event {
        self.delegate?.exchangeTokenCoordinatorDidSelectAddToken(token)
      }
    }
  }
}

extension KNExchangeTokenCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddWallet()
  }

  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.exchangeTokenCoordinatorDidSelectManageWallet()
  }

  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }
}

extension KNExchangeTokenCoordinator: SwapProcessPopupDelegate {
  func swapProcessPopup(_ controller: SwapProcessPopup, action: SwapProcessPopupEvent) {
    controller.dismiss(animated: true) {
      self.transactionStatusVC = nil
      switch action {
      case .openLink(let url):
        self.navigationController.openSafari(with: url)
      case .goToSupport:
        self.navigationController.openSafari(with: "https://t.me/KrystalDefi")
      case .viewToken(let sym):
        if let token = KNSupportedTokenStorage.shared.getTokenWith(symbol: sym) {
          self.delegate?.exchangeTokenCoordinatorDidSelectTokens(token: token)
        }
      case .close:
        print("close popup")
      }
    }
  }
}

extension KNExchangeTokenCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    self.transactionStatusVC = nil
    switch action {
    case .transfer:
      self.openSendTokenView()
    case .openLink(let url):
      self.navigationController.openSafari(with: url)
    case .speedUp(let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .goToSupport:
      self.navigationController.openSafari(with: "https://docs.krystal.app/")
    default:
      break
    }
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
    self.gasFeeSelectorVC = vc
    self.navigationController.present(vc, animated: true, completion: nil)
  }

  fileprivate func openTransactionCancelConfirmPopUpFor(transaction: InternalHistoryTransaction) {
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
    
    viewModel.isCancelMode = true
    viewModel.transaction = transaction
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.gasFeeSelectorVC = vc
    self.navigationController.present(vc, animated: true, completion: nil)
  }
}

extension KNExchangeTokenCoordinator: QRCodeReaderDelegate {
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
      
      do {
        let privateKey = try WalletManager.shared.exportPrivateKey(address: self.currentAddress)
        DispatchQueue.main.async {
          let controller = KNWalletConnectViewController(
            wcURL: url,
            pk: privateKey
          )
          self.navigationController.present(controller, animated: true, completion: nil)
        }
      } catch {
        self.navigationController.showTopBannerView(
          with: "Private Key Error",
          message: "Can not get Private key",
          time: 1.5
        )
      }
    }
  }
}

extension KNExchangeTokenCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      self.rootViewController.coordinatorDidUpdateGasPriceType(type, value: value)
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
    case .minRatePercentageChanged(let percent):
      self.rootViewController.coordinatorDidUpdateMinRatePercentage(percent)
    case .useChiStatusChanged(let status):
      guard let provider = self.session.externalProvider else {
        return
      }
      if status {
        var gasTokenAddressString = ""
        if KNEnvironment.default == .ropsten {
          gasTokenAddressString = "0x0000000000b3F879cb30FE243b4Dfee438691c04"
        } else {
          gasTokenAddressString = "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c"
        }
        
        provider.getAllowance(tokenAddress: gasTokenAddressString) { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let res):
            if res.isZero {
              let viewModel = ApproveTokenViewModelForTokenAddress(address: gasTokenAddressString, remain: res, state: status, symbol: "CHI")
              let viewController = ApproveTokenViewController(viewModel: viewModel)
              viewController.delegate = self
              self.navigationController.present(viewController, animated: true, completion: nil)
            } else {
              self.saveUseGasTokenState(status)
              self.rootViewController.coordinatorUpdateIsUseGasToken(status)
              self.gasFeeSelectorVC?.coordinatorDidUpdateUseGasTokenState(status)
            }
          case .failure(let error):
            self.navigationController.showErrorTopBannerMessage(
              with: NSLocalizedString("error", value: "Error", comment: ""),
              message: error.localizedDescription,
              time: 1.5
            )
            self.rootViewController.coordinatorUpdateIsUseGasToken(!status)
            self.gasFeeSelectorVC?.coordinatorDidUpdateUseGasTokenState(!status)
          }
        }
      } else {
        self.saveUseGasTokenState(status)
        self.rootViewController.coordinatorUpdateIsUseGasToken(status)
      }
    case .updateAdvancedSetting(gasLimit: let gasLimit, maxPriorityFee: let maxPriorityFee, maxFee: let maxFee):
      self.rootViewController.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
    case .updateAdvancedNonce(nonce: let nonce):
      self.rootViewController.coordinatorDidUpdateAdvancedNonce(nonce)
      ///
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

  fileprivate func saveUseGasTokenState(_ state: Bool) {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    }
    data[currentAddress.addressString] = state
    UserDefaults.standard.setValue(data, forKey: Constants.useGasTokenDataKey)
  }

  fileprivate func isApprovedGasToken() -> Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data.keys.contains(currentAddress.addressString)
  }

  fileprivate func isAccountUseGasToken() -> Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data[currentAddress.addressString] ?? false
  }
}

extension KNExchangeTokenCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.exchangeTokenCoordinatorDidSelectManageWallet()
    case .didSelect(let address):
      return
    case .addWallet:
      self.openAddWalletView()
    }
  }
}

extension KNExchangeTokenCoordinator: ChooseRateViewControllerDelegate {
  func chooseRateViewController(_ controller: ChooseRateViewController, didSelect rate: String) {
    self.rootViewController.coordinatorDidUpdatePlatform(rate)
  }
}

extension KNExchangeTokenCoordinator: ApproveTokenViewControllerDelegate {
  func approveTokenViewControllerDidSelectGasSetting(_ controller: ApproveTokenViewController, gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) {
    
  }
  
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: String, value: BigInt) {
    KNGeneralProvider.shared.buildSignTxForApprove(tokenAddress: tokenAddress, address: currentAddress.addressString) { signTx in
      guard let unwrap = signTx else { return }
      KNGeneralProvider.shared.getEstimateGasLimit(transaction: unwrap) { result in
        switch result {
        case.success(let estGas):
          controller.coordinatorDidUpdateGasLimit(estGas)
        default:
          break
        }
      }
    }
  }

  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt) {
    self.navigationController.displayLoading()
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.sendApproveERCTokenAddress(
      address: currentAddress,
      for: address,
      value: Constants.maxValueBigInt,
      gasPrice: KNGasCoordinator.shared.defaultKNGas,
      gasLimit: gasLimit
    ) { approveResult in
      self.navigationController.hideLoading()
      switch approveResult {
      case .success:
        self.saveUseGasTokenState(state)
        self.rootViewController.coordinatorUpdateIsUseGasToken(state)
        self.gasFeeSelectorVC?.coordinatorDidUpdateUseGasTokenState(state)
      case .failure(let error):
        var errorMessage = error.description
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
            errorMessage = message
          }
        }
        self.navigationController.showErrorTopBannerMessage(
          with: "Error",
          message: errorMessage,
          time: 1.5
        )
        self.rootViewController.coordinatorUpdateIsUseGasToken(!state)
        self.gasFeeSelectorVC?.coordinatorDidUpdateUseGasTokenState(!state)
      }
    }
  }

  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt, gasLimit: BigInt) {
    self.navigationController.displayLoading()
    guard let provider = self.session.externalProvider else {
      return
    }
    self.resetAllowanceForTokenIfNeeded(token, remain: remain, gasLimit: gasLimit) { [weak self] resetResult in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch resetResult {
      case .success:
        provider.sendApproveERCToken(address: self.currentAddress, for: token, value: Constants.maxValueBigInt, gasPrice: KNGasCoordinator.shared.defaultKNGas, gasLimit: gasLimit) { (result) in
          switch result {
          case .success:
            self.rootViewController.coordinatorSuccessApprove(token: token)
          case .failure(let error):
            var errorMessage = error.description
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showErrorTopBannerMessage(
              with: "Error",
              message: errorMessage,
              time: 1.5
            )
            self.rootViewController.coordinatorFailApprove(token: token)
          }
        }
      case .failure:
        self.rootViewController.coordinatorFailApprove(token: token)
      }
    }
  }
}

extension KNExchangeTokenCoordinator: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
    self.sendTokenCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddToken(token)
  }

  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.exchangeTokenCoordinatorDidSelectManageWallet()
  }

  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddWallet()
  }
}
