//
//  WithdrawCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/2/21.
//

import Foundation
import Moya
import BigInt
import Result
import APIKit
import JSONRPCKit
import KrystalWallets
import Dependencies
import BaseModule

protocol WithdrawCoordinatorDelegate: class {
  func withdrawCoordinatorDidSelectHistory()
  func withdrawCoordinatorDidSelectEarnMore(balance: LendingBalance)
  func withdrawCoordinatorDidSelectAddToken(_ token: TokenObject)
}

class WithdrawCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var platform: String?
  var balance: LendingBalance?
  var claimBalance: LendingDistributionBalance?
  var balances: [String: Balance] = [:]
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  fileprivate weak var gasPriceSelectVC: GasFeeSelectorPopupViewController?
  weak var delegate: WithdrawCoordinatorDelegate?
  
  var currentChain: ChainType {
    return KNGeneralProvider.shared.currentChain
  }
  
  let etherWeb3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  var isUsingWatchAddress: Bool {
    return currentAddress.isWatchWallet
  }

  lazy var rootViewController: WithdrawConfirmPopupViewController? = {
    guard let balance = self.balance else { return nil }
    let viewModel = WithdrawConfirmPopupViewModel(balance: balance)
    let controller = WithdrawConfirmPopupViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  lazy var withdrawViewController: WithdrawViewController? = {
    guard let balance = self.balance, let platform = self.platform else { return nil }
    let viewModel = WithdrawViewModel(platform: platform, balance: balance)
    let controller = WithdrawViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  lazy var claimViewController: WithdrawConfirmPopupViewController? = {
    guard let balance = self.claimBalance else { return nil }
    let viewModel = ClaimConfirmPopupViewModel(balance: balance)
    let controller = WithdrawConfirmPopupViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    if let controller = self.rootViewController {
      self.navigationController.present(controller, animated: true, completion: nil)
    } else if let controller = self.claimViewController {
      self.navigationController.present(controller, animated: true, completion: nil)
    }
    
  }

  func stop() {
    
  }

  func coordinatorDidUpdatePendingTx() {
    self.withdrawViewController?.coordinatorDidUpdatePendingTx()
  }
}

extension WithdrawCoordinator: WithdrawViewControllerDelegate {
  func withdrawViewController(_ controller: WithdrawViewController, run event: WithdrawViewEvent) {
    switch event {
    case .getWithdrawableAmount(platform: let platform, userAddress: let userAddress, tokenAddress: let tokenAddress):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
      provider.requestWithFilter(.getWithdrawableAmount(platform: platform, userAddress: userAddress, token: tokenAddress)) { [weak self] (result) in
        guard let `self` = self else { return }
        if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let amount = json["amount"] as? String {
          self.withdrawViewController?.coordinatorDidUpdateWithdrawableAmount(amount)
        } else {
          self.withdrawViewController?.coodinatorFailUpdateWithdrawableAmount()
        }
      }
    case .buildWithdrawTx(platform: let platform, token: let token, amount: let amount, gasPrice: let gasPrice, useGasToken: let useGasToken, advancedGasLimit: let advancedGasLimit, advancedPriorityFee: let advancedPriorityFee, advancedMaxGas: let advancedMaxGas, advancedNonce: let advancedNonce, historyTransaction: let historyTransaction):
      if isUsingWatchAddress {
        self.navigationController.showTopBannerView(message: Strings.watchWalletNotSupportOperation)
        return
      }
      controller.displayLoading()
      self.getLatestNonce { [weak self] (nonce) in
        guard let `self` = self else { return }
        let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
        provider.requestWithFilter(.buildWithdrawTx(platform: platform, userAddress: self.currentAddress.addressString, token: token, amount: amount, gasPrice: gasPrice, nonce: nonce, useGasToken: useGasToken)) { (result) in
          if case .success(let resp) = result {
            let decoder = JSONDecoder()
            do {
              let data = try decoder.decode(TransactionResponse.self, from: resp.data)
              if KNGeneralProvider.shared.isUseEIP1559 {
                if let transaction = data.txObject.convertToEIP1559Transaction(advancedGasLimit: advancedGasLimit, advancedPriorityFee: advancedPriorityFee, advancedMaxGas: advancedMaxGas, advancedNonce: advancedNonce) {
                  KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: transaction) { result in
                    switch result {
                    case .success:
                      if let data = EIP1559TransactionSigner().signTransaction(address: self.currentAddress, eip1559Tx: transaction) {
                        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
                          controller.hideLoading()
                          switch sendResult {
                          case .success(let hash):
                            print(hash)
                            NonceCache.shared.increaseNonce(address: self.currentAddress.addressString, chain: KNGeneralProvider.shared.currentChain)
                            
                            historyTransaction.hash = hash
                            historyTransaction.time = Date()
                            historyTransaction.nonce = nonce
                            historyTransaction.eip1559Transaction = transaction
                            EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                            self.withdrawViewController?.coordinatorSuccessSendTransaction()
                            controller.dismiss(animated: true) {
                              self.openTransactionStatusPopUp(transaction: historyTransaction)
                            }
                          case .failure(let error):
                            self.navigationController.showTopBannerView(message: error.localizedDescription)
                          }
                        })
                      }
                    case .failure(let error):
                      self.navigationController.hideLoading()
                      var errorMessage = "Can not estimate Gas Limit"
                      if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                        if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                          errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
                        }
                      }
                      self.navigationController.showErrorTopBannerMessage(message: errorMessage)
                    }
                  }
                }
              } else {
                if let transaction = data.txObject.convertToSignTransaction(address: self.currentAddress.addressString, advancedGasPrice: advancedMaxGas, advancedGasLimit: advancedGasLimit, advancedNonce: advancedNonce) {
                  KNGeneralProvider.shared.getEstimateGasLimit(transaction: transaction) { (result) in
                    switch result {
                    case .success:
                      let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: transaction)
                      switch signResult {
                      case .success(let signedData):
                        KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
                          controller.hideLoading()
                          switch sendResult {
                          case .success(let hash):
                            historyTransaction.hash = hash
                            historyTransaction.time = Date()
                            historyTransaction.nonce = transaction.nonce
                            historyTransaction.transactionObject = transaction.toSignTransactionObject()
                            EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)

                            controller.dismiss(animated: true) {
                              self.openTransactionStatusPopUp(transaction: historyTransaction)
                            }
                          case .failure(let error):
                            var errorMessage = error.description
                            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                                errorMessage = message
                              }
                            }
                            self.navigationController.showTopBannerView(message: errorMessage)
                          }
                        })
                      case .failure:
                        controller.hideLoading()
                      }
                    case .failure(let error):
                      self.navigationController.hideLoading()
                      var errorMessage = "Can not estimate Gas Limit"
                      if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                        if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                          errorMessage = message
                        }
                      }
                      self.navigationController.showErrorTopBannerMessage(message: errorMessage)
                    }
                  }
                } else {
                  controller.hideLoading()
                  self.navigationController.showErrorTopBannerMessage(message: "Watched wallet is not supported")
                }
              }
            } catch let error {
              self.navigationController.showTopBannerView(message: error.localizedDescription)
            }
          } else {
            controller.hideLoading()
          }
        }
      }
    case .updateGasLimit(platform: let platform, token: let token, amount: let amount, gasPrice: let gasPrice, useGasToken: let useGasToken):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
      provider.requestWithFilter(.buildWithdrawTx(platform: platform, userAddress: currentAddress.addressString, token: token, amount: amount, gasPrice: gasPrice, nonce: 1, useGasToken: useGasToken)) { [weak self] (result) in
        guard let `self` = self else { return }
        if case .success(let resp) = result,
            let json = try? resp.mapJSON() as? JSONDictionary ?? [:],
            let txObj = json["txObject"] as? [String: String],
            let gasLimitString = txObj["gasLimit"],
            let to = txObj["to"],
            let gasLimit = BigInt(gasLimitString.drop0x, radix: 16) {
          self.withdrawViewController?.coordinatorDidUpdateGasLimit(value: gasLimit, toAddress: to)
        } else {
          self.withdrawViewController?.coordinatorFailUpdateGasLimit()
        }
      }
    case .checkAllowance(tokenAddress: let tokenAddress, toAddress: let to):
      if currentAddress.isWatchWallet {
        return
      }
      etherWeb3Service.getAllowance(for: currentAddress.addressString, networkAddress: to, tokenAddress: tokenAddress, completion: { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let res):
          self.withdrawViewController?.coordinatorDidUpdateAllowance(token: tokenAddress, allowance: res)
        case .failure:
          self.withdrawViewController?.coordinatorDidFailUpdateAllowance(token: tokenAddress)
        }
      })
    case .sendApprove(tokenAddress: let tokenAddress, remain: let remain, symbol: let symbol, toAddress: let toAddress):
      let vm = ApproveTokenViewModelForTokenAddress(address: tokenAddress, remain: remain, state: false, symbol: symbol)
      vm.toAddress = toAddress
      let vc = ApproveTokenViewController(viewModel: vm)

      vc.delegate = self
      controller.present(vc, animated: true, completion: nil)
    case .openGasPriceSelect(let gasLimit, let selectType, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: selectType, currentRatePercentage: 3, isUseGasToken: self.isAccountUseGasToken(), isContainSlippageSection: false)
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
      self.withdrawViewController?.present(vc, animated: true, completion: nil)
      self.gasPriceSelectVC = vc
      MixPanelManager.track("earn_txn_setting_pop_up_open", properties: ["screenid": "earn_txn_setting_pop_up"])

    }
  }

  func getLatestNonce(completion: @escaping (Int) -> Void) {
    if currentAddress.isWatchWallet {
      return
    }
    etherWeb3Service.getTransactionCount(for: currentAddress.addressString) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let res):
        completion(res)
      case .failure:
        self.getLatestNonce(completion: completion)
      }
    }
  }

  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
}

extension WithdrawCoordinator: KNTransactionStatusPopUpDelegate {
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
    self.gasPriceSelectVC = vc
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
    self.gasPriceSelectVC = vc
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
  }

  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.hash, txHash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
}

extension WithdrawCoordinator: ApproveTokenViewControllerDelegate {
  func approveTokenViewControllerDidSelectGasSetting(_ controller: ApproveTokenViewController, gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) {
    
  }
  
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: String, value: BigInt) {
    
  }

  fileprivate func sendApprove(_ tokenAddress: String, _ toAddress: String?, _ address: String, _ gasLimit: BigInt) {
    let processor = EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
    processor.sendApproveERCTokenAddress(owner: self.currentAddress, tokenAddress: tokenAddress, value: Constants.maxValueBigInt, gasPrice: KNGasCoordinator.shared.defaultKNGas, toAddress: toAddress) { approveResult in
      switch approveResult {
      case .success:
        if address.lowercased() == Constants.gasTokenAddress.lowercased() {
          self.saveUseGasTokenState(true)
          self.withdrawViewController?.coordinatorUpdateIsUseGasToken(true)
        } else {
          self.withdrawViewController?.coordinatorSuccessApprove(token: address)
        }
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.localizedDescription,
          time: 1.5
        )
        self.withdrawViewController?.coordinatorFailApprove(token: address)
      }
    }
  }
  
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt) {
    if currentAddress.isWatchWallet {
      return
    }
    guard remain.isZero else {
      self.resetAllowanceBeforeSend(address, toAddress, address, gasLimit)
      return
    }
    self.sendApprove(address, toAddress, address, gasLimit)
  }

  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt, gasLimit: BigInt) {
  }

  fileprivate func resetAllowanceBeforeSend(_ tokenAddress: String, _ toAddress: String?, _ address: String, _ gasLimit: BigInt) {
    let processor = EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
    processor.sendApproveERCTokenAddress(owner: self.currentAddress, tokenAddress: tokenAddress, value: BigInt(0), gasPrice: KNGasCoordinator.shared.defaultKNGas, toAddress: toAddress) { approveResult in
      switch approveResult {
      case .success:
        self.sendApprove(tokenAddress, toAddress, address, gasLimit)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.localizedDescription,
          time: 1.5
        )
      }
    }
  }
}

extension WithdrawCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      self.withdrawViewController?.coordinatorDidUpdateGasPriceType(type, value: value)
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
    case .useChiStatusChanged(let status):
      if currentAddress.isWatchWallet {
        return
      }
      if status {
        let networkAddress = KNGeneralProvider.shared.networkAddress
        etherWeb3Service.getAllowance(for: currentAddress.addressString, networkAddress: networkAddress, tokenAddress: Constants.gasTokenAddress) { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let res):
            if res.isZero {
              let viewModel = ApproveTokenViewModelForTokenAddress(address: Constants.gasTokenAddress, remain: res, state: status, symbol: "CHI")
              let viewController = ApproveTokenViewController(viewModel: viewModel)
              viewController.delegate = self
              self.withdrawViewController?.present(viewController, animated: true, completion: nil)
            } else {
              self.saveUseGasTokenState(status)
              self.withdrawViewController?.coordinatorUpdateIsUseGasToken(status)
            }
          case .failure(let error):
            self.navigationController.showErrorTopBannerMessage(
              with: NSLocalizedString("error", value: "Error", comment: ""),
              message: error.localizedDescription,
              time: 1.5
            )
            self.withdrawViewController?.coordinatorUpdateIsUseGasToken(!status)
          }
        }
      } else {
        self.saveUseGasTokenState(status)
        self.withdrawViewController?.coordinatorUpdateIsUseGasToken(status)
      }
    case .updateAdvancedSetting(gasLimit: let gasLimit, maxPriorityFee: let maxPriorityFee, maxFee: let maxFee):
      self.withdrawViewController?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
    case .updateAdvancedNonce(nonce: let nonce):
      self.withdrawViewController?.coordinatorDidUpdateAdvancedNonce(nonce)
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

extension WithdrawCoordinator: WithdrawConfirmPopupViewControllerDelegate {
  func withdrawConfirmPopupViewControllerDidSelectFirstButton(_ controller: WithdrawConfirmPopupViewController, balance: LendingBalance?) {
    controller.dismiss(animated: true) {
        guard balance?.chainType == KNGeneralProvider.shared.currentChain else {
          if let chain = balance?.chainType {
              SwitchSpecificChainPopup.show(onViewController: self.navigationController, destChain: chain) {
                  self.withdrawConfirmPopupViewControllerDidSelectFirstButton(controller, balance: balance)
              }
          }
          return
        }

        if let controller = self.withdrawViewController {
          self.navigationController.present(controller, animated: true, completion: {
            controller.coordinatorUpdateIsUseGasToken(self.isAccountUseGasToken())
          })
        }
    }
  }

  func withdrawConfirmPopupViewControllerDidSelectSecondButton(_ controller: WithdrawConfirmPopupViewController, balance: LendingBalance?) {
    if controller == self.claimViewController {
      if currentAddress.isWatchWallet {
        self.navigationController.showTopBannerView(message: Strings.watchWalletNotSupportOperation)
        return
      }
      controller.dismiss(animated: true) {
        guard self.claimBalance?.chainType == KNGeneralProvider.shared.currentChain else {
          if let chain = self.claimBalance?.chainType {
            self.navigationController.showSwitchChainAlert(chain) {
              self.withdrawConfirmPopupViewControllerDidSelectSecondButton(controller, balance: balance)
            }
          }
          return
        }
        
        self.navigationController.displayLoading()
        if self.claimViewController != nil {
          self.getLatestNonce { (nonce) in
            self.buildClaimTx(address: self.currentAddress.addressString, nonce: nonce) { (result) in
              self.navigationController.hideLoading()
              switch result {
              case .success(let txObj):
                if KNGeneralProvider.shared.isUseEIP1559 {
                  if let transaction = txObj.convertToEIP1559Transaction(advancedGasLimit: nil, advancedPriorityFee: nil, advancedMaxGas: nil, advancedNonce: nil) { //TODO: binding advanced setting
                    KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: transaction) { result in
                      switch result {
                      case .success:
                        if let data = EIP1559TransactionSigner().signTransaction(address: self.currentAddress, eip1559Tx: transaction) {
                          KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
                            controller.hideLoading()
                            switch sendResult {
                            case .success(let hash):
                              print(hash)
                              NonceCache.shared.increaseNonce(address: self.currentAddress.addressString, chain: self.currentChain)
                              let historyTransaction = InternalHistoryTransaction(type: .contractInteraction, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: "Claim", transactionDetailDescription: "", transactionObj: nil, eip1559Tx: transaction)
                              historyTransaction.trackingExtraData = self.withdrawViewController?.viewModel.buildExtraInfo()
                              historyTransaction.hash = hash
                              historyTransaction.time = Date()
                              historyTransaction.nonce = nonce
                              historyTransaction.eip1559Transaction = transaction
                              EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)

                              controller.dismiss(animated: true) {
                                self.openTransactionStatusPopUp(transaction: historyTransaction)
                              }
                            case .failure(let error):
                              var errorMessage = "Can not estimate Gas limit"
                              if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                                if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                                  errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
                                }
                              }
                              self.navigationController.showTopBannerView(message: errorMessage)
                            }
                          })
                        }
                      case .failure(let error):
                        self.navigationController.hideLoading()
                        var errorMessage = "Can not estimate Gas Limit"
                        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                            errorMessage = message
                          }
                        }
                        self.navigationController.showErrorTopBannerMessage(message: errorMessage)
                      }
                    }
                  } else {
                    self.navigationController.showErrorTopBannerMessage(message: "Watched wallet is not supported")
                  }
                } else {
                  if let transaction = txObj.convertToSignTransaction(address: self.currentAddress.addressString) {
                    KNGeneralProvider.shared.getEstimateGasLimit(transaction: transaction) { (result) in
                      switch result {
                      case .success:
                        let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: transaction)
                        
                        switch signResult {
                        case .success(let signedData):
                          KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
                            controller.hideLoading()
                            switch sendResult {
                            case .success(let hash):
                              NonceCache.shared.increaseNonce(address: self.currentAddress.addressString, chain: self.currentChain)
                              let historyTransaction = InternalHistoryTransaction(type: .contractInteraction, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: "Claim", transactionDetailDescription: "", transactionObj: transaction.toSignTransactionObject(), eip1559Tx: nil)
//                                historyTransaction.trackingExtraData = self.withdrawViewController?.viewModel.buildExtraInfo()
                              historyTransaction.hash = hash
                              historyTransaction.time = Date()
                              historyTransaction.nonce = transaction.nonce
                              EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                              controller.dismiss(animated: true) {
                                self.openTransactionStatusPopUp(transaction: historyTransaction)
                              }
                            case .failure(let error):
                              controller.hideLoading()
                              var errorMessage = "Can not estimate Gas limit"
                              if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                                if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                                  errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
                                }
                              }
                              self.navigationController.showTopBannerView(message: errorMessage)
                            }
                          })
                        case .failure:
                          controller.hideLoading()
                        }
                      case .failure(let error):
                        var errorMessage = "Can not estimate Gas Limit"
                        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                            errorMessage = message
                          }
                        }
                        self.navigationController.showErrorTopBannerMessage(message: errorMessage)
                      }
                    }
                    
                  } else {
                    self.navigationController.showErrorTopBannerMessage(message: "Watched wallet is not supported")
                  }
                }
              case .failure(let error):
                self.navigationController.showErrorTopBannerMessage(message: error.description)
              }
            }
          }
        }
      }
    } else {
      controller.dismiss(animated: true, completion: {
        guard balance?.chainType == KNGeneralProvider.shared.currentChain else {
          if let chain = balance?.chainType {
            self.navigationController.showSwitchChainAlert(chain) {
              self.withdrawConfirmPopupViewControllerDidSelectSecondButton(controller, balance: balance)
            }
          }
          return
        }
        guard let unwrapped = balance else { return }
        self.delegate?.withdrawCoordinatorDidSelectEarnMore(balance: unwrapped)
      })
    }
    
  }
  
   func buildClaimTx(address: String, nonce: Int, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.buildClaimTx(address: address, nonce: nonce)) { (result) in
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
}

extension WithdrawCoordinator: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
    
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.withdrawCoordinatorDidSelectAddToken(token)
  }
  
}
