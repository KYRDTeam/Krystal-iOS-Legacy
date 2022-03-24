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
import TrustCore
import QRCodeReaderViewController
import WalletConnect
import MBProgressHUD
import APIKit
import JSONRPCKit
import WalletConnectSwift
//swiftlint:disable file_length
protocol NavigationBarDelegate: class {
  func viewControllerDidSelectHistory(_ controller: KNBaseViewController)
  func viewControllerDidSelectWallets(_ controller: KNBaseViewController)
}

protocol EarnCoordinatorDelegate: class {
  func earnCoordinatorDidSelectAddWallet()
  func earnCoordinatorDidSelectWallet(_ wallet: Wallet)
  func earnCoordinatorDidSelectManageWallet()
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
  
  private(set) var session: KNSession
  fileprivate var historyCoordinator: KNHistoryCoordinator?
  
  lazy var rootViewController: EarnOverviewViewController = {
    let controller = EarnOverviewViewController(self.depositViewController)
    controller.delegate = self
    controller.navigationDelegate = self
    controller.wallet = self.session.wallet
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
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }
  
  weak var delegate: EarnCoordinatorDelegate?
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
    
  }
  
  func start() {
    //TODO: pesist token data in to disk then load into memory
    self.navigationController.viewControllers = [self.rootViewController]
    self.menuViewController.coordinatorUpdateNewSession(wallet: self.session.wallet)
    self.getLendingOverview()
  }

  func stop() {
    
  }

  // MARK: Bussiness code
  func getLendingOverview() {
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getLendingOverview) { [weak self] (result) in
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
          Storage.store(self.lendingTokens, as: KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName)
        } else {
          self.loadCachedLendingTokens()
        }
      }
    }
  }
  
  func loadCachedLendingTokens() {
    if let tokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName, as: [TokenData].self) {
      self.lendingTokens = tokens
      self.menuViewController.coordinatorDidUpdateLendingToken(self.lendingTokens)
    }
  }
  
  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.earnViewController?.coordinatorUpdateTokenBalance(self.balances)
    self.earnSwapViewController?.coordinatorUpdateTokenBalance(self.balances)
    self.rootViewController.coordinatorDidUpdateDidUpdateTokenList()
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    self.menuViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    self.earnViewController?.coordinatorUpdateNewSession(wallet: session.wallet)
    self.earnSwapViewController?.coordinatorUpdateNewSession(wallet: session.wallet)
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(session)
    self.balances = [:]
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
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
    self.menuViewController.coordinatorDidUpdatePendingTx()
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
    let viewModel = EarnViewModel(data: token, wallet: self.session.wallet)
    let controller = EarnViewController(viewModel: viewModel)
    controller.delegate = self
    controller.navigationDelegate = self
    self.earnViewController = controller
    self.earnViewController?.coordinatorUpdateTokenBalance(self.balances)
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  func appCoordinatorDidUpdateChain() {
    self.navigationController.popToRootViewController(animated: false)
    self.rootViewController.coordinatorDidUpdateChain()
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
      provider.request(.buildSwapAndDepositTx(
                        lendingPlatform: platform,
                        userAddress: self.session.wallet.address.description,
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
          userAddress: self.session.wallet.address.description,
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
    case .openEarnSwap(let token, let wallet):
      let fromToken = KNGeneralProvider.shared.quoteTokenObject.toTokenData()
      let viewModel = EarnSwapViewModel(to: token, from: fromToken, wallet: wallet)
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
      guard let provider = self.session.externalProvider, let address = Address(string: token.address) else {
        return
      }
      provider.getAllowance(tokenAddress: address) { getAllowanceResult in
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
    provider.request(.buildSwapAndDepositTx(
                      lendingPlatform: lendingPlatform,
                      userAddress: self.session.wallet.address.description,
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
    let address = self.session.wallet.address.description
    provider.request(.getAllRates(src: src, dst: dest, amount: amt, focusSrc: focusSrc, userAddress: address)) { [weak self] result in
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
    provider.request(.getRefPrice(src: src, dst: dest)) { [weak self] result in
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
    return data[self.session.wallet.address.description] ?? false
  }
}

extension EarnCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
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
        guard let tokenAddress = Address(string: gasTokenAddressString) else {
          return
        }
        provider.getAllowance(tokenAddress: tokenAddress) { [weak self] result in
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
            var errorMessage = "Speedup failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
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
            var errorMessage = "Cancel failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
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
            var errorMessage = "Speedup failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
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
            var errorMessage = "Cancel failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
          }
        }
      }
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
    return data.keys.contains(self.session.wallet.address.description)
  }
  
  fileprivate func saveUseGasTokenState(_ state: Bool) {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    }
    data[self.session.wallet.address.description] = state
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
      guard let unwrap = eip1559Transaction, let data = provider.signContractGenericEIP1559Transaction(unwrap) else { return }
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
      provider.signTransactionData(from: unwrap) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let signedData):
          KNGeneralProvider.shared.sendSignedTransactionData(signedData.0, completion: { sendResult in
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
      navigationController.present(controller, animated: true)
    }
    */
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

  fileprivate func openSendTokenView() {
    let from: TokenObject = KNGeneralProvider.shared.quoteTokenObject
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }
}

extension EarnCoordinator: SpeedUpCustomGasSelectDelegate {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent) {
    switch event {
    case .done(let transaction, let newValue):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
        savedTx?.state = .speedup
        if KNGeneralProvider.shared.isUseEIP1559 {
          if let speedupTx = transaction.eip1559Transaction?.toSpeedupTransaction(gasPrice: newValue), let data = provider.signContractGenericEIP1559Transaction(speedupTx) {
            KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
              switch sendResult {
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
                var errorMessage = "Speedup failed"
                if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                  if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                    errorMessage = message
                  }
                }
                self.navigationController.showTopBannerView(message: errorMessage)
              }
            })
          }
        } else {
          if let speedupTx = transaction.transactionObject?.toSpeedupTransaction(account: account, gasPrice: newValue) {
            speedupTx.send(provider: provider) { (result) in
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
                var errorMessage = "Speedup failed"
                if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                  if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                    errorMessage = message
                  }
                }
                self.navigationController.showTopBannerView(message: errorMessage)
              }
            }
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
  }

  fileprivate func sendSpeedUpSwapTransactionFor(transaction: Transaction, availableTokens: [TokenObject], newPrice: BigInt) {
    guard let provider = self.session.externalProvider else {
      return
    }
    guard let nouce = Int(transaction.nonce) else { return }
    guard let localizedOperation = transaction.localizedOperations.first else { return }
    guard let filteredToken = availableTokens.first(where: { (token) -> Bool in
      return token.symbol == localizedOperation.symbol
    }) else { return }
    let amount: BigInt = {
      return transaction.value.amountBigInt(decimals: localizedOperation.decimals) ?? BigInt(0)
    }()
    let gasLimit: BigInt = {
      return transaction.gasUsed.amountBigInt(units: .wei) ?? BigInt(0)
    }()
    provider.getTransactionByHash(transaction.id) { [weak self] (pendingTx, _) in
      guard let `self` = self else { return }
      if let fetchedTx = pendingTx, !fetchedTx.input.isEmpty {
        provider.speedUpSwapTransaction(
          for: filteredToken,
          amount: amount,
          nonce: nouce,
          data: fetchedTx.input,
          gasPrice: newPrice,
          gasLimit: gasLimit) { sendResult in
          switch sendResult {
          case .success(let txHash):
            let tx = transaction.convertToSpeedUpTransaction(newHash: txHash, newGasPrice: newPrice.displayRate(decimals: 0).removeGroupSeparator())
            self.session.updatePendingTransactionWithHash(hashTx: transaction.id, ultiTransaction: tx, state: .speedingUp, completion: {
//              self.openTransactionStatusPopUp(transaction: tx)
            })
          case .failure:
            KNNotificationUtil.postNotification(
              for: kTransactionDidUpdateNotificationKey,
              object: nil,
              userInfo: [Constants.transactionIsCancel: TransactionType.speedup]
            )
          }
        }
      }
    }
  }
}

extension EarnCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction) {
    if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
      let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
      
      if KNGeneralProvider.shared.isUseEIP1559 {
        if let cancelTx = transaction.eip1559Transaction?.toCancelTransaction(), let data = provider.signContractGenericEIP1559Transaction(cancelTx) {
          saved?.state = .cancel
          saved?.type = .transferETH
          saved?.transactionSuccessDescription = "-0 ETH"
          print("[EIP1559] cancel tx \(cancelTx)")
          print("[EIP1559] cancel hex tx \(data.hexString)")
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
              var errorMessage = "Cancel failed"
              if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                  errorMessage = message
                }
              }
              self.navigationController.showTopBannerView(message: errorMessage)
            }
          })
        }
      } else {
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
              var errorMessage = "Cancel failed"
              if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                  errorMessage = message
                }
              }
              self.navigationController.showTopBannerView(message: errorMessage)
            }
          }
        }
      }
    } else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
    }
  }
}

extension EarnCoordinator: ChooseRateViewControllerDelegate {
  func chooseRateViewController(_ controller: ChooseRateViewController, didSelect rate: String) {
    self.earnSwapViewController?.coordinatorDidUpdatePlatform(rate)
  }
}

extension EarnCoordinator: ApproveTokenViewControllerDelegate {
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?) {
    self.navigationController.displayLoading()
    guard let provider = self.session.externalProvider, let gasTokenAddress = Address(string: address) else {
      return
    }
    provider.sendApproveERCTokenAddress(
      for: gasTokenAddress,
      value: BigInt(2).power(256) - BigInt(1),
      gasPrice: KNGasCoordinator.shared.defaultKNGas) { approveResult in
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

  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt) {
    self.navigationController.displayLoading()
    guard let provider = self.session.externalProvider else {
      return
    }
    self.resetAllowanceForTokenIfNeeded(token, remain: remain) { [weak self] resetResult in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch resetResult {
      case .success:
        provider.sendApproveERCToken(for: token, value: BigInt(2).power(256) - BigInt(1), gasPrice: KNGasCoordinator.shared.defaultKNGas) { (result) in
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

  fileprivate func resetAllowanceForTokenIfNeeded(_ token: TokenObject, remain: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    if remain.isZero {
      completion(.success(true))
      return
    }
    let gasPrice = KNGasCoordinator.shared.defaultKNGas
    provider.sendApproveERCToken(
      for: token,
      value: BigInt(0),
      gasPrice: gasPrice
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
    self.historyCoordinator = nil
    self.historyCoordinator = KNHistoryCoordinator(
      navigationController: self.navigationController,
      session: self.session
    )
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator?.start()
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
  
  func viewControllerDidSelectWallets(_ controller: KNBaseViewController) {
    let viewModel = WalletsListViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.currentWallet
    )
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }
}

extension EarnCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.earnCoordinatorDidSelectManageWallet()
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
      self.delegate?.earnCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.earnCoordinatorDidSelectAddWallet()
    }
  }
}

extension EarnCoordinator: QRCodeReaderDelegate {
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

extension EarnCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.earnCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.earnCoordinatorDidSelectAddWallet()
  }
  
  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.earnCoordinatorDidSelectManageWallet()
  }

  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }

  func historyCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.earnCoordinatorDidSelectWallet(wallet)
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
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController, session: self.session)
      coordinator.delegate = self
      coordinator.platform = platform
      coordinator.balance = balance
      coordinator.start()
      self.withdrawCoordinator = coordinator
    case .claim(balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController, session: self.session)
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
  func sendTokenCoordinatorDidClose() {
    self.sendCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.earnCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.earnCoordinatorDidSelectWallet(wallet)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
  }
  
  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.earnCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.earnCoordinatorDidSelectAddWallet()
  }
}

extension EarnCoordinator: WithdrawCoordinatorDelegate {
  func withdrawCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.earnCoordinatorDidSelectAddToken(token)
  }
  
  func withdrawCoordinatorDidSelectAddWallet() {}
  
  func withdrawCoordinatorDidSelectWallet(_ wallet: Wallet) {}
  
  func withdrawCoordinatorDidSelectManageWallet() {}
  
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
