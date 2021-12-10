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

let RETRYMAXCOUNT = 5

class RewardCoordinator: Coordinator {
  fileprivate var session: KNSession
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var gasLimit: BigInt = KNGasConfiguration.claimRewardGasLimitDefault
  var currentHash = ""
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  fileprivate var claimRetryCount = 0
  fileprivate var claimDetailRetryCount = 0

  lazy var rootViewController: RewardsViewController = {
    let controller = RewardsViewController()
    controller.delegate = self
    controller.session = self.session
    return controller
  }()

  var claimRewardController: ClaimRewardsController?

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
    loadRewards()
  }

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
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
    let hud = MBProgressHUD.showAdded(to: self.rootViewController.view, animated: true)
    self.updateLoginToken { completed in
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      self.claimRetryCount += 1
      self.loadRewards()
    }
  }
  
  func handleUpdateLoginTokenForClaimRewardDetail() {
    let hud = MBProgressHUD.showAdded(to: self.rootViewController.view, animated: true)
    self.updateLoginToken { completed in
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      self.claimDetailRetryCount += 1
      self.loadClaimRewards()
    }
  }

  func loadRewards() {
    guard case .real(_) = self.session.wallet.type else {
      //watch wallet dont'show reward
      return
    }

    let hud = MBProgressHUD.showAdded(to: self.rootViewController.view, animated: true)
    if self.claimRetryCount > RETRYMAXCOUNT {
      hud.hide(animated: true)
      return
    }
    guard let loginToken = Storage.retrieve(self.session.wallet.address.description + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      self.handleUpdateLoginTokenForClaimReward()
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.session.wallet.address.description

    provider.request(.getRewards(address: address, accessToken: loginToken.token)) { (result) in
      DispatchQueue.main.async {
        hud.hide(animated: true)
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
        if error.code == 401 {
          // case error 401 mean login token is expired, need update it
          self.handleUpdateLoginTokenForClaimReward()
        }
      }
    }
  }

  func loadClaimRewards(shouldShowPopup: Bool = false) {
    let hud = MBProgressHUD.showAdded(to: self.rootViewController.view, animated: true)
    if self.claimDetailRetryCount > RETRYMAXCOUNT {
      hud.hide(animated: true)
      return
    }
    guard let loginToken = Storage.retrieve(self.session.wallet.address.description + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      self.handleUpdateLoginTokenForClaimRewardDetail()
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.session.wallet.address.description

    provider.request(.getClaimRewards(address: address, accessToken: loginToken.token)) { (result) in
      DispatchQueue.main.async {
        hud.hide(animated: true)
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
            let txObject = TxObject(from: from, to: to, data: dataString, value: value, gasPrice: gasPrice, nonce: nonce, gasLimit: gasLimitString)
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
    let address = self.session.wallet.address.description
    provider.request(.checkEligibleWallet(address: address)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let isEligible = json["result"] as? Bool {
        completion(isEligible)
      } else {
        completion(false)
      }
    }
  }
  
  func sendSignedTransactionData(_ signedData: Data, transaction: SignTransaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
      switch sendResult {
      case .success(let hash):
          self.currentHash = hash
          provider.minTxCount += 1
          let tx = transaction.toTransaction(hash: hash, fromAddr: self.session.wallet.address.description, type: .withdraw)
          self.session.addNewPendingTransaction(tx)
          let description = self.rootViewController.viewModel.totalBalanceString()
          let detailDescription = tx.to
        let historyTransaction = InternalHistoryTransaction(type: .claimReward, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: description, transactionDetailDescription: detailDescription, transactionObj: transaction.toSignTransactionObject(), eip1559Tx: nil)
          historyTransaction.hash = hash
          historyTransaction.time = Date()
          historyTransaction.nonce = transaction.nonce
          EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
          self.claimRewardController?.dismiss(animated: true, completion: {
            self.openTransactionStatusPopUp(transaction: historyTransaction)
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
        provider.signTransactionData(from: transaction) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let signedData):
            self.sendSignedTransactionData(signedData.0, transaction: transaction)
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

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    loadRewards()
  }
}

extension RewardCoordinator: RewardsViewControllerDelegate {
  func loadClaimRewards(_ controller: RewardsViewController) {
    self.loadClaimRewards(shouldShowPopup: true)
  }

  func showClaimRewardVC(_ controller: RewardsViewController, model: KNRewardModel, txObject: TxObject) {
    let totalValue = "$" + StringFormatter.currencyString(value: model.value, symbol: model.symbol)
    let viewModel = ClaimRewardsViewModel(totalTokenBalance: model.amount, totalTokenSymbol: model.rewardSymbol, totalTokensValue: totalValue, tokenIconURL: model.rewardImage, gasLimit: self.gasLimit, session: self.session, txObject: txObject)

    let claimPopupViewController = ClaimRewardsController(viewModel: viewModel)
    claimPopupViewController.delegate = self
    self.claimRewardController = claimPopupViewController
    self.rootViewController.present(claimPopupViewController, animated: true, completion: nil)
  }
}

extension RewardCoordinator: ClaimRewardsControllerDelegate {
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
          if let transaction = newTxObject.convertToSignTransaction(wallet: self.session.wallet) {
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
      self.navigationController.openSafari(with: "https://support.krystal.app")
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

extension RewardCoordinator: SpeedUpCustomGasSelectDelegate {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent) {
    switch event {
    case .done(let transaction, let newValue):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
        savedTx?.state = .speedup
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

extension RewardCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction) {
    if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
      let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
      
      if KNGeneralProvider.shared.isUseEIP1559 {
        if let cancelTx = transaction.eip1559Transaction?.toCancelTransaction(), let data = provider.signContractGenericEIP1559Transaction(cancelTx) {
          saved?.state = .cancel
          saved?.type = .transferETH
          saved?.transactionSuccessDescription = "-0 ETH"
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
      }
    } else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
    }
  }
}

extension RewardCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
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
