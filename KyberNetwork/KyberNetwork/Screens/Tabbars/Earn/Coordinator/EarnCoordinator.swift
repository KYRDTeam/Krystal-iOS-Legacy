//
//  EarnCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/26/21.
//

import Foundation
import Moya
import BigInt
import Result
import QRCodeReaderViewController
import MBProgressHUD
import APIKit
import JSONRPCKit
import WalletConnectSwift
import KrystalWallets
//swiftlint:disable file_length
protocol NavigationBarDelegate: class {
  func viewControllerDidSelectHistory(_ controller: KNBaseViewController)
}

protocol EarnCoordinatorDelegate: class {
  func earnCoordinatorDidSelectAddToken(_ token: TokenObject)
}
//swiftlint:disable function_body_length
class EarnCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var lendingTokens: [TokenData] = []
  var balances: [String: Balance] = [:]
  var withdrawCoordinator: WithdrawCoordinator?
  var sendCoordinator: KNSendTokenViewCoordinator?
  
  fileprivate var historyCoordinator: KNHistoryCoordinator?
  
  var currentAddress: KAddress {
    return session.address
  }
  
  var session: KNSession {
    return AppDelegate.session
  }
  
  lazy var rootViewController: EarnOverviewViewController = {
    let controller = EarnOverviewViewController(self.depositViewController)
    controller.delegate = self
    controller.navigationDelegate = self
//    controller.wallet = self.session.wallet
    return controller
  }()
  
  lazy var menuViewController: EarnMenuViewController = {
    let viewModel = EarnMenuViewModel()
    let viewController = EarnMenuViewController(viewModel: viewModel)
    viewController.delegate = self
    viewController.navigationDelegate = self
    return viewController
  }()
  
  lazy var depositViewController: OverviewDepositViewController = {
    let controller = OverviewDepositViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var tutorialViewController: EarnTutorialViewController = {
    let controller = EarnTutorialViewController()
    return controller
  }()
  
  fileprivate weak var earnViewController: EarnViewController?
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  fileprivate weak var earnSwapViewController: EarnSwapViewController?

  weak var delegate: EarnCoordinatorDelegate?
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    
  }
  
  func start() {
    //TODO: pesist token data in to disk then load into memory
    self.navigationController.viewControllers = [self.rootViewController]
    self.getLendingOverview()
    self.observeAppEvents()
  }

  func stop() {
    self.removeObservers()
  }

  // MARK: Bussiness code
  func getLendingOverview() {
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.requestWithFilter(.getLendingOverview) { [weak self] (result) in
        guard let `self` = self else { return }
        if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["result"] as? [JSONDictionary] {
          let addresses = result.map { (dict) -> String in
            return dict["address"] as? String ?? ""
          }.map { $0.lowercased() }
          var lendingTokensData: [TokenData] = []
          let lendingTokens = KNSupportedTokenStorage.shared.findTokensWithAddresses(addresses: addresses)
          //Get token decimal to init token data
          lendingTokens.forEach { (token) in
            let tokenDict = result.first { (tokenDict) -> Bool in
              if let tokenAddress = tokenDict["address"] as? String {
                return token.address.lowercased() == tokenAddress.lowercased()
              } else {
                return false
              }
            }
            var platforms: [LendingPlatformData] = []
            if let platformDicts = tokenDict?["overview"] as? [JSONDictionary] {
              platformDicts.forEach { (platformDict) in
                let platform = LendingPlatformData(
                  name: platformDict["name"] as? String ?? "",
                  supplyRate: platformDict["supplyRate"] as? Double ?? 0.0,
                  stableBorrowRate: platformDict["stableBorrowRate"] as? Double ?? 0.0,
                  variableBorrowRate: platformDict["variableBorrowRate"] as? Double ?? 0.0,
                  distributionSupplyRate: platformDict["distributionSupplyRate"] as? Double ?? 0.0,
                  distributionBorrowRate: platformDict["distributionBorrowRate"] as? Double ?? 0.0
                )
                platforms.append(platform)
              }
            }
            let tokenData = TokenData(address: token.address, name: token.name, symbol: token.symbol, decimals: token.decimals, lendingPlatforms: platforms, logo: "")
            lendingTokensData.append(tokenData)
          }
          self.lendingTokens = lendingTokensData
          self.menuViewController.coordinatorDidUpdateLendingToken(self.lendingTokens)
          self.depositViewController.coordinatorDidUpdateDidUpdateTokenList()
          Storage.store(self.lendingTokens, as: KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName)
        } else {
          self.loadCachedLendingTokens()
        }
      }
    }
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
  
  @objc func appDidSwitchAddress() {
    self.rootViewController.coordinatorAppSwitchAddress()
//    self.menuViewController.coordinatorAppSwitchAddress()
    self.earnViewController?.coordinatorAppSwitchAddress()
    self.earnSwapViewController?.coordinatorAppSwitchAddress()
    self.balances = [:]
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }
  
  func loadCachedLendingTokens() {
    let tokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName, as: [TokenData].self) ?? []
    self.lendingTokens = tokens
    self.menuViewController.coordinatorDidUpdateLendingToken(self.lendingTokens)
    self.depositViewController.coordinatorDidUpdateDidUpdateTokenList()
  }
  
  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.earnViewController?.coordinatorUpdateTokenBalance(self.balances)
    self.earnSwapViewController?.coordinatorUpdateTokenBalance(self.balances)
    self.rootViewController.coordinatorDidUpdateDidUpdateTokenList()
  }

  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if self.sendCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.historyCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    if self.withdrawCoordinator?.appCoordinatorUpdateTransaction(tx) == true { return true }
    if let txHash = self.transactionStatusVC?.transaction.hash, txHash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.depositViewController.coordinatorDidUpdateDidUpdateTokenList()
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorPendingTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate()
    self.earnViewController?.coordinatorDidUpdatePendingTx()
    self.earnSwapViewController?.coordinatorDidUpdatePendingTx()
//    self.menuViewController.coordinatorDidUpdatePendingTx()
    self.rootViewController.coordinatorDidUpdatePendingTx()
    self.depositViewController.coordinatorDidUpdateDidUpdateTokenList()
    self.withdrawCoordinator?.coordinatorDidUpdatePendingTx()
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoodinatorDidOpenEarnView(tokenAddress: String) {
    guard let token = self.lendingTokens.first(where: { (item) -> Bool in
      return item.address.lowercased() == tokenAddress.lowercased()
    }) else {
      return
    }
    self.openEarnViewController(token: token)
  }
  
  fileprivate func openEarnViewController(token: TokenData) {
    let viewModel = EarnViewModel(data: token)
    let controller = EarnViewController(viewModel: viewModel)
    controller.delegate = self
    controller.navigationDelegate = self
    self.earnViewController = controller
    self.earnViewController?.coordinatorUpdateTokenBalance(self.balances)
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  func appCoordinatorDidUpdateChain() {
    self.navigationController.popToRootViewController(animated: false)
    self.loadCachedLendingTokens()
    self.getLendingOverview()
    self.sendCoordinator?.appCoordinatorDidUpdateChain()
  }
  
  func appCoodinatorDidUpdateHideBalanceStatus(_ status: Bool) {
    self.rootViewController.coordinatorDidUpdateHideBalanceStatus(status)
  }
  
  func appCoordinatorDidUpdateTokenList() {
    
  }
}

extension EarnCoordinator: EarnMenuViewControllerDelegate {
  func earnMenuViewControllerDidSelectToken(controller: EarnMenuViewController, token: TokenData) {
    self.openEarnViewController(token: token)
  }
}

extension EarnCoordinator: EarnViewControllerDelegate {
  func earnViewController(_ controller: AbstractEarnViewControler, run event: EarnViewEvent) {
    switch event {
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let selectType, let isSwap, let percent, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: selectType, currentRatePercentage: percent, isUseGasToken: self.isAccountUseGasToken(), isContainSlippageSection: isSwap)
      viewModel.baseGasLimit = baseGasLimit
      viewModel.updateGasPrices(
        fast: KNGasCoordinator.shared.fastKNGas,
        medium: KNGasCoordinator.shared.standardKNGas,
        slow: KNGasCoordinator.shared.lowKNGas,
        superFast: KNGasCoordinator.shared.superFastKNGas
      )
      viewModel.advancedGasLimit = advancedGasLimit
      viewModel.advancedMaxPriorityFee = advancedPriorityFee
      viewModel.advancedMaxFee = advancedMaxFee
      viewModel.advancedNonce = advancedNonce
      let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
      vc.delegate = self
      self.getLatestNonce { nonce in
        vc.coordinatorDidUpdateCurrentNonce(nonce)
      }
      self.navigationController.present(vc, animated: true, completion: nil)
    case .getGasLimit(let platform, let src, let dest, let amount, let minDestAmount, let gasPrice, let isSwap):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.requestWithFilter(.buildSwapAndDepositTx(
                        lendingPlatform: platform,
                        userAddress: currentAddress.addressString,
                        src: src,
                        dest: dest,
                        srcAmount: amount,
                        minDestAmount: minDestAmount,
                        gasPrice: gasPrice,
                        nonce: 1,
                        hint: "",
                        useGasToken: false
      )) { (result) in
        if case .success(let resp) = result,
            let json = try? resp.mapJSON() as? JSONDictionary ?? [:],
            let txObj = json["txObject"] as? [String: String],
            let gasLimitString = txObj["gasLimit"],
            let gasLimit = BigInt(gasLimitString.drop0x, radix: 16) {
          controller.coordinatorDidUpdateGasLimit(gasLimit, platform: platform, tokenAdress: dest)
        } else {
          controller.coordinatorFailUpdateGasLimit()
        }
      }
    case .buildTx(let platform, let src, let dest, let amount, let minDestAmount, let gasPrice, let isSwap):
      self.navigationController.displayLoading()
      self.getLatestNonce { [weak self] (nonce) in
        guard let `self` = self else { return }
        self.buildTx(
          lendingPlatform: platform,
          userAddress: self.currentAddress.addressString,
          src: src,
          dest: dest,
          srcAmount: amount,
          minDestAmount: minDestAmount,
          gasPrice: gasPrice,
          nonce: nonce
        ) { (result) in
          DispatchQueue.main.async {
            self.navigationController.hideLoading()
          }
          
          switch result {
          case .success(let txObj):
            controller.coordinatorDidUpdateSuccessTxObject(txObject: txObj)
          case .failure(let error):
            controller.coordinatorFailUpdateTxObject(error: error)
          }
        }
      }
    case .confirmTx(let fromToken, let toToken, let platform, let fromAmount, let toAmount, let gasPrice, let gasLimit, let transaction, let eip1559Transaction, let isSwap, let rawTransaction, let minReceivedData, let priceImpact, let maxSlippage):
      self.navigationController.displayLoading()
      if let unwrap = transaction {
        KNGeneralProvider.shared.getEstimateGasLimit(transaction: unwrap) { (result) in
          self.navigationController.hideLoading()
          switch result {
          case .success:
            if isSwap {
              let viewModel = EarnSwapConfirmViewModel(platform: platform, fromToken: fromToken, fromAmount: fromAmount, toToken: toToken, toAmount: toAmount, gasPrice: unwrap.gasPrice, gasLimit: unwrap.gasLimit, transaction: unwrap, eip1559Transaction: eip1559Transaction, rawTransaction: rawTransaction, minReceiveAmount: minReceivedData.1, minReceiveTitle: minReceivedData.0, priceImpact: priceImpact, maxSlippage: maxSlippage)
              let controller = EarnSwapConfirmViewController(viewModel: viewModel)
              controller.delegate = self
              self.navigationController.present(controller, animated: true, completion: nil)
            } else {
              let viewModel = EarnConfirmViewModel(platform: platform, token: toToken, amount: toAmount, gasPrice: unwrap.gasPrice, gasLimit: unwrap.gasLimit, transaction: unwrap, eip1559Transaction: eip1559Transaction, rawTransaction: rawTransaction)
              let controller = EarnConfirmViewController(viewModel: viewModel)
              controller.delegate = self
              self.navigationController.present(controller, animated: true, completion: nil)
            }
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
      } else if let unwrap = eip1559Transaction {
        let txGasPrice = BigInt(unwrap.maxGasFee, radix: 16) ?? BigInt(0)
        let txGasLimit = BigInt(unwrap.gasLimit, radix: 16) ?? BigInt(0)
        KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: unwrap) { result in
          self.navigationController.hideLoading()
          switch result {
          case .success:
            if isSwap {
              let viewModel = EarnSwapConfirmViewModel(platform: platform, fromToken: fromToken, fromAmount: fromAmount, toToken: toToken, toAmount: toAmount, gasPrice: txGasPrice, gasLimit: txGasLimit, transaction: nil, eip1559Transaction: unwrap, rawTransaction: rawTransaction, minReceiveAmount: minReceivedData.1, minReceiveTitle: minReceivedData.0, priceImpact: priceImpact, maxSlippage: maxSlippage)
              let controller = EarnSwapConfirmViewController(viewModel: viewModel)
              controller.delegate = self
              self.navigationController.present(controller, animated: true, completion: nil)
            } else {
              let viewModel = EarnConfirmViewModel(platform: platform, token: toToken, amount: toAmount, gasPrice: txGasPrice, gasLimit: txGasLimit, transaction: nil, eip1559Transaction: unwrap, rawTransaction: rawTransaction)
              let controller = EarnConfirmViewController(viewModel: viewModel)
              controller.delegate = self
              self.navigationController.present(controller, animated: true, completion: nil)
            }
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
      }
    case .openEarnSwap(let token):
      let viewModel: EarnSwapViewModel = {
        let quoteToken = KNGeneralProvider.shared.quoteTokenObject.toTokenData()
        if token == quoteToken {
          return EarnSwapViewModel(to: token, from: nil)
        } else {
          return EarnSwapViewModel(to: token, from: quoteToken)
        }
      }()
      let controller = EarnSwapViewController(viewModel: viewModel)
      controller.delegate = self
      controller.navigationDelegate = self
      self.navigationController.pushViewController(controller, animated: true)
      controller.coordinatorUpdateTokenBalance(self.balances)
      self.earnSwapViewController = controller
    case .getAllRates(from: let from, to: let to, amount: let amount, focusSrc: let focusSrc):
      self.getAllRates(from: from, to: to, amount: amount, focusSrc: focusSrc)
    case .openChooseRate(from: let from, to: let to, rates: let rates, gasPrice: let gasPrice, amountFrom : let amountFrom):
      let viewModel = ChooseRateViewModel(from: from, to: to, data: rates, gasPrice: gasPrice, isDeposit: true, amountFrom: amountFrom)
      let vc = ChooseRateViewController(viewModel: viewModel)
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    case .getRefPrice(from: let from, to: let to):
      self.getRefPrice(from: from, to: to)
    case .checkAllowance(token: let token):
      guard let provider = self.session.externalProvider else {
        return
      }
      provider.getAllowance(tokenAddress: token.address) { getAllowanceResult in
        switch getAllowanceResult {
        case .success(let res):
          controller.coordinatorDidUpdateAllowance(token: token, allowance: res)
        case .failure:
          controller.coordinatorDidFailUpdateAllowance(token: token)
        }
      }
    case .sendApprove(token: let token, remain: let remain):
      guard let tokenObject = KNSupportedTokenStorage.shared.get(forPrimaryKey: token.address) else {
        return
      }
      let vc = ApproveTokenViewController(viewModel: ApproveTokenViewModelForTokenObject(token: tokenObject, res: remain))
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    case .searchToken(isSwap: let isSwap):
      let tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
      if isSwap {
        let viewModel = KNSearchTokenViewModel(
          supportedTokens: tokens
        )
        let controller = KNSearchTokenViewController(viewModel: viewModel)
        controller.loadViewIfNeeded()
        controller.delegate = self
        self.navigationController.present(controller, animated: true, completion: nil)
        controller.updateBalances(self.balances)
      } else {
        let earnTokenAddresses = self.lendingTokens.map { $0.address.lowercased() }
        let earnTokenObjects = tokens.filter { (item) -> Bool in
          return earnTokenAddresses.contains(item.contract.lowercased())
        }
        let viewModel = KNSearchTokenViewModel(
          supportedTokens: earnTokenObjects
        )
        let controller = KNSearchTokenViewController(viewModel: viewModel)
        controller.loadViewIfNeeded()
        controller.delegate = self
        self.navigationController.present(controller, animated: true, completion: nil)
        controller.updateBalances(self.balances)
      }
    }
  }

  func getLatestNonce(completion: @escaping (Int) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getTransactionCount { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let res):
        completion(res)
      case .failure:
        self.getLatestNonce(completion: completion)
      }
    }
  }
  
  func buildTx(lendingPlatform: String, userAddress: String, src: String, dest: String, srcAmount: String, minDestAmount: String, gasPrice: String, nonce: Int, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.requestWithFilter(.buildSwapAndDepositTx(
                      lendingPlatform: lendingPlatform,
                      userAddress: currentAddress.addressString,
                      src: src,
                      dest: dest,
                      srcAmount: srcAmount,
                      minDestAmount: minDestAmount,
                      gasPrice: gasPrice,
                      nonce: nonce,
                      hint: "",
                      useGasToken: self.isApprovedGasToken()
    )) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(TransactionResponse.self, from: resp.data)
          completion(.success(data.txObject))
        } catch let error {
          completion(.failure(AnyError(NSError(domain: error.localizedDescription, code: 404, userInfo: nil))))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getAllRates(from: TokenData, to: TokenData, amount: BigInt, focusSrc: Bool) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let src = from.address.lowercased()
    let dest = to.address.lowercased()
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
          self.earnSwapViewController?.coordinatorDidUpdateRates(from: from, to: to, srcAmount: amount, rates: sortedRate)
        } catch let error {
          self.earnSwapViewController?.coordinatorFailUpdateRates()
        }
      } else {
        self.earnSwapViewController?.coordinatorFailUpdateRates()
      }
    }
  }
  
  func getRefPrice(from: TokenData, to: TokenData) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let src = from.address.lowercased()
    let dest = to.address.lowercased()
    provider.requestWithFilter(.getRefPrice(src: src, dst: dest)) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let change = json["refPrice"] as? String, let sources = json["sources"] as? [String] {
        self.earnSwapViewController?.coordinatorSuccessUpdateRefPrice(from: from, to: to, change: change, source: sources)
      } else {
        //TODO: add handle for fail load ref price
      }
    }
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

extension EarnCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      guard let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler else {
        return
      }
      viewController.coordinatorDidUpdateGasPriceType(type, value: value)
    case .helpPressed(let tag):
      var message = "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised()
      switch tag {
      case 1:
        message = "gas.limit.help".toBeLocalised()
      case 2:
        message = "max.priority.fee.help".toBeLocalised()
      case 3:
        message = "max.fee.help".toBeLocalised()
      default:
        break
      }
      self.navigationController.showBottomBannerView(
        message: message,
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .minRatePercentageChanged(let percent):
      guard let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler else {
        return
      }
      viewController.coordinatorDidUpdateMinRatePercentage(percent)
    case .useChiStatusChanged(let status):
      guard let provider = self.session.externalProvider else {
        return
      }
      guard let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler else {
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
              viewController.coordinatorUpdateIsUseGasToken(status)
            }
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
            viewController.coordinatorUpdateIsUseGasToken(status)
          }
        }
      } else {
        self.saveUseGasTokenState(status)
        viewController.coordinatorUpdateIsUseGasToken(status)
      }
    case .updateAdvancedSetting(gasLimit: let gasLimit, maxPriorityFee: let maxPriorityFee, maxFee: let maxFee):
      guard let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler else {
        return
      }
      viewController.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
    case .updateAdvancedNonce(nonce: let nonce):
      guard let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler else {
        return
      }
      viewController.coordinatorDidUpdateAdvancedNonce(nonce)
    case .speedupTransactionSuccessfully(let speedupTransaction):
      self.openTransactionStatusPopUp(transaction: speedupTransaction)
    case .cancelTransactionSuccessfully(let cancelTransaction):
      self.openTransactionStatusPopUp(transaction: cancelTransaction)
    case .speedupTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    case .cancelTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    case .resetSetting:
      break
    default:
      break
    }
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
  
  fileprivate func saveUseGasTokenState(_ state: Bool) {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    }
    data[currentAddress.addressString] = state
    UserDefaults.standard.setValue(data, forKey: Constants.useGasTokenDataKey)
  }
}

extension EarnCoordinator: EarnConfirmViewControllerDelegate {
  func kConfirmEarnSwapViewControllerOpenGasPriceSelect() {
    self.earnSwapViewController?.coordinatorEditTransactionSetting()
  }

  func earnConfirmViewController(_ controller: KNBaseViewController, didConfirm transaction: SignTransaction?, eip1559Transaction: EIP1559Transaction?, amount: String, netAPY: String, platform: LendingPlatformData, historyTransaction: InternalHistoryTransaction) {
    guard let provider = self.session.externalProvider else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
      return
    }
    if KNGeneralProvider.shared.isUseEIP1559 {
      guard let unwrap = eip1559Transaction, let data = EIP1559TransactionSigner().signTransaction(address: currentAddress, eip1559Tx: unwrap) else { return }
      self.navigationController.displayLoading()
      KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
        switch sendResult {
        case .success(let hash):
          provider.minTxCount += 1
          historyTransaction.hash = hash
          historyTransaction.time = Date()
          historyTransaction.nonce = Int(unwrap.nonce) ?? 0
          EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
          self.openTransactionStatusPopUp(transaction: historyTransaction)
          self.transactionStatusVC?.earnAmountString = amount
          self.transactionStatusVC?.netAPYEarnString = netAPY
          self.transactionStatusVC?.earnPlatform = platform
 
          self.earnViewController?.coordinatorSuccessSendTransaction()
          self.earnSwapViewController?.coordinatorSuccessSendTransaction()
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
        self.navigationController.hideLoading()
      })
    } else {
      guard let unwrap = transaction else { return }
      self.navigationController.displayLoading()
      let signResult = EthereumTransactionSigner().signTransaction(address: currentAddress, transaction: unwrap)
      switch signResult {
      case .success(let signedData):
        KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
          self.navigationController.hideLoading()
          switch sendResult {
          case .success(let hash):
            print(hash)
            provider.minTxCount += 1
            historyTransaction.hash = hash
            historyTransaction.time = Date()
            historyTransaction.nonce = unwrap.nonce
            EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
            self.openTransactionStatusPopUp(transaction: historyTransaction)
            self.transactionStatusVC?.earnAmountString = amount
            self.transactionStatusVC?.netAPYEarnString = netAPY
            self.transactionStatusVC?.earnPlatform = platform
            self.earnViewController?.coordinatorSuccessSendTransaction()
            self.earnSwapViewController?.coordinatorSuccessSendTransaction()
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
      case .failure:
        self.navigationController.hideLoading()
      }
    }
  }

  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.transactionStatusVC = controller
    self.navigationController.present(controller, animated: true, completion: nil)
  }
}

extension EarnCoordinator: KNTransactionStatusPopUpDelegate { //TODO: popup screen should has coordinator
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    switch action {
    case .transfer:
      self.openSendTokenView()
    case .openLink(let url):
      self.navigationController.openSafari(with: url)
    case .speedUp(let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .backToInvest:
      self.navigationController.popToRootViewController(animated: true)
    case .newSave:
      break
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
    self.navigationController.present(vc, animated: true, completion: nil)
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
    self.sendCoordinator = coordinator
  }
}

extension EarnCoordinator: ChooseRateViewControllerDelegate {
  func chooseRateViewController(_ controller: ChooseRateViewController, didSelect rate: String) {
    self.earnSwapViewController?.coordinatorDidUpdatePlatform(rate)
  }
}

extension EarnCoordinator: ApproveTokenViewControllerDelegate {
  func approveTokenViewControllerDidSelectGasSetting(_ controller: ApproveTokenViewController, gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) {
    
  }
  
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: String, value: BigInt) {
    
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
        self.earnSwapViewController?.coordinatorUpdateIsUseGasToken(state)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.localizedDescription,
          time: 1.5
        )
        self.earnSwapViewController?.coordinatorUpdateIsUseGasToken(!state)
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
            if let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler {
              viewController.coordinatorSuccessApprove(token: token)
            }
          case .failure(let error):
            self.navigationController.showErrorTopBannerMessage(
              with: NSLocalizedString("error", value: "Error", comment: ""),
              message: error.localizedDescription,
              time: 1.5
            )
            if let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler {
              viewController.coordinatorFailApprove(token: token)
            }
           
          }
        }
      case .failure:
        if let viewController = self.navigationController.viewControllers.last as? AbstractEarnViewControler {
          viewController.coordinatorFailApprove(token: token)
        }
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
  
  fileprivate func openHistoryScreen() {
    switch KNGeneralProvider.shared.currentChain {
    case .solana:
      let coordinator = KNTransactionHistoryCoordinator(navigationController: navigationController, type: .solana)
      coordinator.delegate = self
      coordinate(coordinator: coordinator)
    default:
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(navigationController: self.navigationController)
      self.historyCoordinator?.delegate = self
      self.historyCoordinator?.appDidSwitchAddress()
      self.historyCoordinator?.start()
    }
  }
}

extension EarnCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true) {
      if case .select(let token) = event {
        if self.navigationController.viewControllers.last == self.earnSwapViewController {
          self.earnSwapViewController?.coordinatorUpdateSelectedToken(token.toTokenData())
        } else {
          guard let lendingToken = self.lendingTokens.first(where: { (item) -> Bool in
            return item.address.lowercased() == token.contract.lowercased()
          }) else { return }
          self.earnViewController?.coordinatorUpdateSelectedToken(lendingToken)
        }
      } else if case .add(let token) = event {
        self.delegate?.earnCoordinatorDidSelectAddToken(token)
      }
    }
  }
}

extension EarnCoordinator: NavigationBarDelegate {
  func viewControllerDidSelectHistory(_ controller: KNBaseViewController) {
    self.openHistoryScreen()
  }
}

extension EarnCoordinator: KNHistoryCoordinatorDelegate {
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.earnCoordinatorDidSelectAddToken(token)
  }

  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }
}

extension EarnCoordinator: EarnOverviewViewControllerDelegate {
  
  func earnOverviewViewControllerDidSelectExplore(_ controller: EarnOverviewViewController) {
    self.navigationController.pushViewController(self.menuViewController, animated: true)
  }
}

extension EarnCoordinator: OverviewDepositViewControllerDelegate {
  func overviewDepositViewController(_ controller: OverviewDepositViewController, run event: OverviewDepositViewEvent) {
    switch event {
    case .withdrawBalance(platform: let platform, balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController)
      coordinator.delegate = self
      coordinator.platform = platform
      coordinator.balance = balance
      coordinator.start()
      self.withdrawCoordinator = coordinator
      MixPanelManager.track("earn_withdraw_pop_up_open", properties: ["screenid": "earn_withdraw_pop_up"])
    case .claim(balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController)
      coordinator.claimBalance = balance
      coordinator.start()
//      coordinator.delegate = self
      self.withdrawCoordinator = coordinator
    case .depositMore:
      self.navigationController.pushViewController(self.menuViewController, animated: true)
    }
  }
}

extension EarnCoordinator: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.earnCoordinatorDidSelectAddToken(token)
  }
  
}

extension EarnCoordinator: WithdrawCoordinatorDelegate {
  
  func withdrawCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.earnCoordinatorDidSelectAddToken(token)
  }
  
  func withdrawCoordinatorDidSelectHistory() {}
  
  func withdrawCoordinatorDidSelectEarnMore(balance: LendingBalance) {
    guard let token = self.lendingTokens.first(where: { (item) -> Bool in
      return item.address.lowercased() == balance.address.lowercased()
    })
    else {
      return
    }
    self.openEarnViewController(token: token)
  }
}
