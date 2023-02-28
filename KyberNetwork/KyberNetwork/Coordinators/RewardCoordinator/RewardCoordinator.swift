//
//  RewardCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 13/10/2021.
//

import UIKit
import Moya
import BigInt
import Result
import APIKit
import JSONRPCKit
import MBProgressHUD
import KrystalWallets
import BaseModule

let RETRYMAXCOUNT = 5

class RewardCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var gasLimit: BigInt = KNGasConfiguration.claimRewardGasLimitDefault
  var currentHash = ""
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  fileprivate var claimRetryCount = 0
  fileprivate var claimDetailRetryCount = 0
  
  var session: KNSession {
    return AppDelegate.session
  }
  
  lazy var rootViewController: RewardsViewController = {
    let controller = RewardsViewController()
    controller.delegate = self
    return controller
  }()
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  var claimRewardController: ClaimRewardsController?
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
    loadRewards()
  }
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    //    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.rootViewController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
  
  func updateLoginToken(_ completion: @escaping (Bool) -> Void) {
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      appDelegate.coordinator.doLogin(completion)
    }
  }
  
  func handleUpdateLoginTokenForClaimReward() {
    self.rootViewController.showLoadingHUD()
    self.updateLoginToken { completed in
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      self.claimRetryCount += 1
      self.loadRewards()
    }
  }
  
  func handleUpdateLoginTokenForClaimRewardDetail() {
    self.rootViewController.showLoadingHUD()
    self.updateLoginToken { completed in
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      self.claimDetailRetryCount += 1
      self.loadClaimRewards()
    }
  }
  
  func loadRewards() {
    //    guard case .real(_) = self.session.wallet.type else {
    //      //watch wallet dont'show reward
    //      return
    //    }
    
    if currentAddress.isWatchWallet {
      return
    }
    
    self.rootViewController.showLoadingHUD()
    if self.claimRetryCount > RETRYMAXCOUNT {
      self.rootViewController.hideLoading()
      return
    }
    guard let loginToken = Storage.retrieve(currentAddress.addressString + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      self.handleUpdateLoginTokenForClaimReward()
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.currentAddress.addressString
    
    provider.requestWithFilter(.getRewards(address: address, accessToken: loginToken.token)) { (result) in
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let errorMsg = json["error"] as? String {
            let statusCode = data.statusCode
            if statusCode == 401 && self.claimRetryCount < RETRYMAXCOUNT {
              // case error 401 mean login token is expired, need update it
              self.handleUpdateLoginTokenForClaimReward()
            } else {
              self.navigationController.showErrorTopBannerMessage(message: errorMsg)
            }
            return
          }
          
          var rewardModels: [KNRewardModel] = []
          if let rewards = json["claimableRewards"] as? [JSONDictionary] {
            rewardModels = rewards.map({ item in
              return KNRewardModel(json: item)
            })
          }
          
          var rewardDetailModel: [KNRewardModel] = []
          if let rewardDetails = json["rewards"] as? [JSONDictionary] {
            rewardDetailModel = rewardDetails.map({ item in
              return KNRewardModel(json: item)
            })
          }
          
          var supportedChains: [Int] = []
          if let chainArrays = json["supportedChainIDs"] as? [Int] {
            supportedChains = chainArrays
          }
          
          self.rootViewController.coordinatorDidUpdateRewards(rewards: rewardModels, rewardDetails: rewardDetailModel, supportedChain: supportedChains)
        }
      case .failure(let error):
        print("[Get rewards] \(error.localizedDescription)")
        if error.errorCode() == 401 {
          // case error 401 mean login token is expired, need update it
          self.handleUpdateLoginTokenForClaimReward()
        }
      }
    }
  }
  
  func loadClaimRewards(shouldShowPopup: Bool = false) {
    self.rootViewController.showLoadingHUD()
    if self.claimDetailRetryCount > RETRYMAXCOUNT {
      self.rootViewController.hideLoading()
      return
    }
    guard let loginToken = Storage.retrieve(currentAddress.addressString + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      self.handleUpdateLoginTokenForClaimRewardDetail()
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = currentAddress.addressString
    
    provider.requestWithFilter(.getClaimRewards(address: address, accessToken: loginToken.token)) { (result) in
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let txJson = json["claimTx"] as? JSONDictionary,
             let from = txJson["from"] as? String,
             let to = txJson["to"] as? String,
             let value = txJson["value"] as? String,
             let dataString = txJson["data"] as? String,
             let gasPrice = txJson["gasPrice"] as? String,
             let nonce = txJson["nonce"] as? String,
             let gasLimitString = txJson["gasLimit"] as? String {
            self.gasLimit = BigInt(gasLimitString.drop0x, radix: 16) ?? BigInt(0)
            let txObject = TxObject(nonce: nonce, from: from, to: to, data: dataString, value: value, gasPrice: gasPrice, gasLimit: gasLimitString)
            self.rootViewController.coordinatorDidUpdateClaimRewards(shouldShowPopup, txObject: txObject)
          } else if let errorMsg = json["error"] as? String {
            let statusCode = data.statusCode
            if statusCode == 401 && self.claimDetailRetryCount < RETRYMAXCOUNT {
              // case error 401 mean login token is expired, need update it
              self.handleUpdateLoginTokenForClaimRewardDetail()
            } else {
              self.navigationController.showErrorTopBannerMessage(message: errorMsg)
            }
          }
        }
        
      case .failure(let error):
        print("[Claim reward] \(error.localizedDescription)")
        if error.code == 401 {
          // case error 401 mean login token is expired, need update it
          self.handleUpdateLoginTokenForClaimRewardDetail()
        }
      }
    }
  }
  
  func checkEligibleWallet(completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.currentAddress.addressString
    provider.requestWithFilter(.checkEligibleWallet(address: address)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let isEligible = json["result"] as? Bool {
        completion(isEligible)
      } else {
        completion(false)
      }
    }
  }
  
  func sendSignedTransactionData(_ signedData: Data, transaction: SignTransaction) {
    let currentChain = KNGeneralProvider.shared.currentChain
    KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
      switch sendResult {
      case .success(let hash):
        self.currentHash = hash
        NonceCache.shared.increaseNonce(address: self.currentAddress.addressString, chain: currentChain)
        let tx = transaction.toTransaction(hash: hash, fromAddr: self.currentAddress.addressString, type: .withdraw)
        AppDelegate.session.addNewPendingTransaction(tx)
        let description = self.rootViewController.viewModel.totalBalanceString()
        let detailDescription = tx.to
        let historyTransaction = InternalHistoryTransaction(type: .claimReward, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: description, transactionDetailDescription: detailDescription, transactionObj: transaction.toSignTransactionObject(), eip1559Tx: nil)
        historyTransaction.trackingExtraData = self.rootViewController.viewModel.buildExtraData()
        historyTransaction.hash = hash
        historyTransaction.time = Date()
        historyTransaction.nonce = transaction.nonce
        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
        self.claimRewardController?.dismiss(animated: true, completion: {
          self.openTransactionStatusPopUp(transaction: historyTransaction)
          self.claimRewardController = nil
        })
      case .failure(let error):
        self.navigationController.showTopBannerView(message: error.localizedDescription)
      }
    })
  }
  
  func getEstimateGasLimit(transaction: SignTransaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    KNGeneralProvider.shared.getEstimateGasLimit(transaction: transaction) { (result) in
      switch result {
      case .success:
        let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: transaction)
        switch signResult {
        case .success(let signedData):
          self.sendSignedTransactionData(signedData, transaction: transaction)
        case .failure(let error):
          self.navigationController.hideLoading()
          var errorMessage = "Can not sign transaction data"
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = message
            }
          }
          self.navigationController.showErrorTopBannerMessage(message: errorMessage)
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
  
  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if !self.currentHash.isEmpty && self.currentHash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      self.loadRewards()
      if tx.state == .done {
        self.rootViewController.viewModel.shouldDisableClaim = false
        self.rootViewController.updateUI()
      }
      return true
    }
    return false
  }
  
  func appCoordinatorSwitchAddress() {
    loadRewards()
  }
}

extension RewardCoordinator: RewardsViewControllerDelegate {

  func reloadData(_ controller: RewardsViewController) {
    loadRewards()
  }
  
  func loadClaimRewards(_ controller: RewardsViewController) {
    self.loadClaimRewards(shouldShowPopup: true)
  }
  
  func showClaimRewardVC(_ controller: RewardsViewController, model: KNRewardModel, txObject: TxObject) {
    let totalValue = "$" + StringFormatter.currencyString(value: model.value, symbol: model.symbol)
    let viewModel = ClaimRewardsViewModel(totalTokenBalance: model.amount, totalTokenSymbol: model.rewardSymbol, totalTokensValue: totalValue, tokenIconURL: model.rewardImage, gasLimit: self.gasLimit, txObject: txObject)
    
    let claimPopupViewController = ClaimRewardsController(viewModel: viewModel)
    claimPopupViewController.delegate = self
    self.claimRewardController = claimPopupViewController
    self.rootViewController.present(claimPopupViewController, animated: true, completion: nil)
  }
}

extension RewardCoordinator: ClaimRewardsControllerDelegate {
  func didDismiss() {
    self.claimRewardController = nil
  }
  
  func didSelectAdvancedSetting(gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) {
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: selectType, currentRatePercentage: 0, isUseGasToken: false, isContainSlippageSection: false)
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
    self.claimRewardController?.present(vc, animated: true, completion: nil)
  }
  
  func didClaimRewards(_ controller: ClaimRewardsController, txObject: TxObject) {
    self.rootViewController.viewModel.shouldDisableClaim = true
    self.rootViewController.updateUI()
    controller.viewModel.shouldDisableClaimButton = true
    controller.updateUI()
    controller.showLoading()
    
    self.checkEligibleWallet { isEligible in
      if isEligible {
        self.getLatestNonce { (nonce) in
          let newTxObject = txObject.newTxObjectWithNonce(nonce: nonce)
          if let transaction = newTxObject.convertToSignTransaction(address: self.currentAddress.addressString) {
            self.getEstimateGasLimit(transaction: transaction)
          } else {
            self.navigationController.showErrorTopBannerMessage(message: "Watched wallet is not supported")
          }
        }
      }
    }
  }
}

extension RewardCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    switch action {
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
}

extension RewardCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
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
    case .speedupTransactionSuccessfully(let speedupTransaction):
      self.openTransactionStatusPopUp(transaction: speedupTransaction)
    case .cancelTransactionSuccessfully(let cancelTransaction):
      self.openTransactionStatusPopUp(transaction: cancelTransaction)
    case .speedupTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    case .cancelTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    case .gasPriceChanged(let type, let value):
      self.claimRewardController?.coordinatorDidUpdateSetting(type: type, value: value)
    case .updateAdvancedSetting(gasLimit: let gasLimit, maxPriorityFee: let maxPriorityFee, maxFee: let maxFee):
      self.claimRewardController?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
    case .updateAdvancedNonce(nonce: let nonce):
      self.claimRewardController?.coordinatorDidUpdateAdvancedNonce(nonce)
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
