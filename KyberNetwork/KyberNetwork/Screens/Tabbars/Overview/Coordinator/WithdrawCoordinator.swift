//
//  WithdrawCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/2/21.
//

import Foundation
import Moya
import BigInt
import TrustCore
import Result
import APIKit
import JSONRPCKit

protocol WithdrawCoordinatorDelegate: class {
  func withdrawCoordinatorDidSelectAddWallet()
  func withdrawCoordinatorDidSelectWallet(_ wallet: Wallet)
  func withdrawCoordinatorDidSelectManageWallet()
  func withdrawCoordinatorDidSelectHistory()
  func withdrawCoordinatorDidSelectEarnMore(balance: LendingBalance)
  func withdrawCoordinatorDidSelectAddToken(_ token: TokenObject)
}

class WithdrawCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  private(set) var session: KNSession
  var platform: String?
  var balance: LendingBalance?
  var claimBalance: LendingDistributionBalance?
  var balances: [String: Balance] = [:]
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  fileprivate weak var gasPriceSelectVC: GasFeeSelectorPopupViewController?
  weak var delegate: WithdrawCoordinatorDelegate?

  lazy var rootViewController: WithdrawConfirmPopupViewController? = {
    guard let balance = self.balance else { return nil }
    let viewModel = WithdrawConfirmPopupViewModel(balance: balance)
    let controller = WithdrawConfirmPopupViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  lazy var withdrawViewController: WithdrawViewController? = {
    guard let balance = self.balance, let platform = self.platform else { return nil }
    let viewModel = WithdrawViewModel(platform: platform, session: self.session, balance: balance)
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

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
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
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getWithdrawableAmount(platform: platform, userAddress: userAddress, token: tokenAddress)) { [weak self] (result) in
        guard let `self` = self else { return }
        if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let amount = json["amount"] as? String {
          self.withdrawViewController?.coordinatorDidUpdateWithdrawableAmount(amount)
        } else {
          self.withdrawViewController?.coodinatorFailUpdateWithdrawableAmount()
        }
      }
    case .buildWithdrawTx(platform: let platform, token: let token, amount: let amount, gasPrice: let gasPrice, useGasToken: let useGasToken, advancedGasLimit: let advancedGasLimit, advancedPriorityFee: let advancedPriorityFee, advancedMaxGas: let advancedMaxGas, advancedNonce: let advancedNonce, historyTransaction: let historyTransaction):
      guard let blockchainProvider = self.session.externalProvider else {
        self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
        return
      }
      controller.displayLoading()
      self.getLatestNonce { [weak self] (nonce) in
        guard let `self` = self else { return }
        let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
        provider.request(.buildWithdrawTx(platform: platform, userAddress: self.session.wallet.address.description, token: token, amount: amount, gasPrice: gasPrice, nonce: nonce, useGasToken: useGasToken)) { (result) in
          if case .success(let resp) = result {
            let decoder = JSONDecoder()
            do {
              let data = try decoder.decode(TransactionResponse.self, from: resp.data)
              if KNGeneralProvider.shared.isUseEIP1559 {
                if let transaction = data.txObject.convertToEIP1559Transaction(advancedGasLimit: advancedGasLimit, advancedPriorityFee: advancedPriorityFee, advancedMaxGas: advancedMaxGas, advancedNonce: advancedNonce) {
                  KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: transaction) { result in
                    switch result {
                    case .success:
                      if let data = blockchainProvider.signContractGenericEIP1559Transaction(transaction) {
                        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
                          controller.hideLoading()
                          switch sendResult {
                          case .success(let hash):
                            print(hash)
                            blockchainProvider.minTxCount += 1
                            
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
                          errorMessage = message
                        }
                      }
                      self.navigationController.showErrorTopBannerMessage(message: errorMessage)
                    }
                  }
                }
              } else {
                if let transaction = data.txObject.convertToSignTransaction(wallet: self.session.wallet) {
                  KNGeneralProvider.shared.getEstimateGasLimit(transaction: transaction) { (result) in
                    switch result {
                    case .success:
                      blockchainProvider.signTransactionData(from: transaction) { [weak self] result in
                        guard let `self` = self else { return }
                        switch result {
                        case .success(let signedData):
                          KNGeneralProvider.shared.sendSignedTransactionData(signedData.0, completion: { sendResult in
                            controller.hideLoading()
                            switch sendResult {
                            case .success(let hash):
                              print(hash)
                              blockchainProvider.minTxCount += 1
                              
                              historyTransaction.hash = hash
                              historyTransaction.time = Date()
                              historyTransaction.nonce = transaction.nonce
                              historyTransaction.transactionObject = transaction.toSignTransactionObject()
                              EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)

                              controller.dismiss(animated: true) {
                                self.openTransactionStatusPopUp(transaction: historyTransaction)
                              }
                            case .failure(let error):
                              self.navigationController.showTopBannerView(message: error.localizedDescription)
                            }
                          })
                        case .failure:
                          controller.hideLoading()
                        }
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
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.buildWithdrawTx(platform: platform, userAddress: self.session.wallet.address.description, token: token, amount: amount, gasPrice: gasPrice, nonce: 1, useGasToken: useGasToken)) { [weak self] (result) in
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
      guard let provider = self.session.externalProvider, let address = Address(string: tokenAddress) else {
        return
      }
      provider.getAllowance(tokenAddress: address, toAddress: Address(string: to)) { [weak self] getAllowanceResult in
        guard let `self` = self else { return }
        switch getAllowanceResult {
        case .success(let res):
          self.withdrawViewController?.coordinatorDidUpdateAllowance(token: tokenAddress, allowance: res)
        case .failure:
          self.withdrawViewController?.coordinatorDidFailUpdateAllowance(token: tokenAddress)
        }
      }
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
      self.navigationController.openSafari(with: "https://support.krystal.app")
    default:
      break
    }
  }

  fileprivate func openTransactionSpeedUpViewController(transaction: InternalHistoryTransaction) {
    let viewModel = SpeedUpCustomGasSelectViewModel(transaction: transaction)
    let controller = SpeedUpCustomGasSelectViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    navigationController.present(controller, animated: true)
  }

  fileprivate func openTransactionCancelConfirmPopUpFor(transaction: InternalHistoryTransaction) {
    let viewModel = KNConfirmCancelTransactionViewModel(transaction: transaction)
    let confirmPopup = KNConfirmCancelTransactionPopUp(viewModel: viewModel)
    confirmPopup.delegate = self
    self.navigationController.present(confirmPopup, animated: true, completion: nil)
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
  }
  
  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.hash, txHash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
}

extension WithdrawCoordinator: SpeedUpCustomGasSelectDelegate {
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
                self.navigationController.showTopBannerView(message: error.description)
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
                self.navigationController.showTopBannerView(message: error.description)
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
}

extension WithdrawCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction) {
    if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
      let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
      saved?.state = .cancel
      saved?.type = .transferETH
      saved?.transactionSuccessDescription = "-0 ETH"
      if KNGeneralProvider.shared.isUseEIP1559 {
        if let cancelTx = transaction.eip1559Transaction?.toCancelTransaction(), let data = provider.signContractGenericEIP1559Transaction(cancelTx) {
          print(data.hexString)
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
        if let cancelTx = transaction.transactionObject?.toCancelTransaction(account: account) {
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
      }
    } else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
    }
  }
}

extension WithdrawCoordinator: ApproveTokenViewControllerDelegate {
  fileprivate func sendApprove(_ provider: KNExternalProvider, _ tokenAddress: Address, _ toAddress: String?, _ address: String) {
    provider.sendApproveERCTokenAddress(for: tokenAddress, value: BigInt(2).power(256) - BigInt(1), gasPrice: KNGasCoordinator.shared.defaultKNGas, toAddress: toAddress) { approveResult in
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
  
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?) {
    guard let provider = self.session.externalProvider, let tokenAddress = Address(string: address) else {
      return
    }
    guard remain.isZero else {
      self.resetAllowanceBeforeSend(provider, tokenAddress, toAddress, address)
      return
    }
    self.sendApprove(provider, tokenAddress, toAddress, address)
  }

  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt) {
  }

  fileprivate func resetAllowanceBeforeSend(_ provider: KNExternalProvider, _ tokenAddress: Address, _ toAddress: String?, _ address: String) {
    provider.sendApproveERCTokenAddress(for: tokenAddress, value: BigInt(0), gasPrice: KNGasCoordinator.shared.defaultKNGas, toAddress: toAddress) { approveResult in
      switch approveResult {
      case .success:
        self.sendApprove(provider, tokenAddress, toAddress, address)
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
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      self.withdrawViewController?.coordinatorDidUpdateGasPriceType(type, value: value)
    case .helpPressed:
      self.navigationController.showBottomBannerView(
        message: "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised(),
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .useChiStatusChanged(let status):
      guard let provider = self.session.externalProvider else {
        return
      }

      if status {
        guard let tokenAddress = Address(string: Constants.gasTokenAddress) else {
          return
        }
        provider.getAllowance(tokenAddress: tokenAddress) { [weak self] result in
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

extension WithdrawCoordinator: WithdrawConfirmPopupViewControllerDelegate {
  func withdrawConfirmPopupViewControllerDidSelectFirstButton(_ controller: WithdrawConfirmPopupViewController, balance: LendingBalance?) {
    controller.dismiss(animated: true) {
      if let controller = self.withdrawViewController {
        self.navigationController.present(controller, animated: true, completion: {
          controller.coordinatorUpdateIsUseGasToken(self.isAccountUseGasToken())
        })
      }
    }
  }

  func withdrawConfirmPopupViewControllerDidSelectSecondButton(_ controller: WithdrawConfirmPopupViewController, balance: LendingBalance?) {
    if controller == self.claimViewController {
      guard let blockchainProvider = self.session.externalProvider else {
        self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
        return
      }
      controller.dismiss(animated: true) {
        self.navigationController.displayLoading()
        if self.claimViewController != nil {
          self.getLatestNonce { (nonce) in
            self.buildClaimTx(address: self.session.wallet.address.description, nonce: nonce) { (result) in
              self.navigationController.hideLoading()
              switch result {
              case .success(let txObj):
                if KNGeneralProvider.shared.isUseEIP1559 {
                  if let transaction = txObj.convertToEIP1559Transaction(advancedGasLimit: nil, advancedPriorityFee: nil, advancedMaxGas: nil, advancedNonce: nil) { //TODO: binding advanced setting
                    KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: transaction) { result in
                      switch result {
                      case .success:
                        if let data = blockchainProvider.signContractGenericEIP1559Transaction(transaction) {
                          KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
                            controller.hideLoading()
                            switch sendResult {
                            case .success(let hash):
                              print(hash)
                              blockchainProvider.minTxCount += 1
                              let historyTransaction = InternalHistoryTransaction(type: .contractInteraction, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: "Claim", transactionDetailDescription: "", transactionObj: nil, eip1559Tx: transaction)
                              historyTransaction.hash = hash
                              historyTransaction.time = Date()
                              historyTransaction.nonce = nonce
                              historyTransaction.eip1559Transaction = transaction
                              EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)

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
                  if let transaction = txObj.convertToSignTransaction(wallet: self.session.wallet) {
                    KNGeneralProvider.shared.getEstimateGasLimit(transaction: transaction) { (result) in
                      switch result {
                      case .success:
                        blockchainProvider.signTransactionData(from: transaction) { [weak self] result in
                          guard let `self` = self else { return }
                          switch result {
                          case .success(let signedData):
                            KNGeneralProvider.shared.sendSignedTransactionData(signedData.0, completion: { sendResult in
                              controller.hideLoading()
                              switch sendResult {
                              case .success(let hash):
                                print(hash)
                                blockchainProvider.minTxCount += 1

                                let historyTransaction = InternalHistoryTransaction(type: .contractInteraction, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: "Claim", transactionDetailDescription: "", transactionObj: transaction.toSignTransactionObject(), eip1559Tx: nil)
                                historyTransaction.hash = hash
                                historyTransaction.time = Date()
                                historyTransaction.nonce = transaction.nonce
                                EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                                controller.dismiss(animated: true) {
                                  self.openTransactionStatusPopUp(transaction: historyTransaction)
                                }
                              case .failure(let error):
                                controller.hideLoading()
                                self.navigationController.showTopBannerView(message: error.localizedDescription)
                              }
                            })
                          case .failure:
                            controller.hideLoading()
                          }
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
        guard let unwrapped = balance else { return }
        self.delegate?.withdrawCoordinatorDidSelectEarnMore(balance: unwrapped)
      })
    }
    
  }
  
   func buildClaimTx(address: String, nonce: Int, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.buildClaimTx(address: address, nonce: nonce)) { (result) in
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
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.withdrawCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.withdrawCoordinatorDidSelectWallet(wallet)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.delegate?.withdrawCoordinatorDidSelectHistory()
  }
  
  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.withdrawCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.withdrawCoordinatorDidSelectAddWallet()
  }
  
  
}
