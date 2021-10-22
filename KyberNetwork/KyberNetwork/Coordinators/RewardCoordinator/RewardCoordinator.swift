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

class RewardCoordinator: Coordinator {
  fileprivate var session: KNSession
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var gasLimit: BigInt = KNGasConfiguration.claimRewardGasLimitDefault
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?

  lazy var rootViewController: RewardsViewController = {
    let controller = RewardsViewController()
    controller.delegate = self
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
  
  func loadRewards() {
    guard let loginToken = Storage.retrieve(self.session.wallet.address.description + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        self.loadRewards()
      }
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.session.wallet.address.description
    let hud = MBProgressHUD.showAdded(to: self.rootViewController.view, animated: true)
    
    provider.request(.getRewards(address: address, accessToken: loginToken.token)) { (result) in
      DispatchQueue.main.async {
        hud.hide(animated: true)
      }
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
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

 //         Storage.store(data.overview, as: self.session.wallet.address.description + Constants.referralOverviewStoreFileName)
          self.rootViewController.coordinatorDidUpdateRewards(rewards: rewardModels, rewardDetails: rewardDetailModel, supportedChain: supportedChains)
        }
      case .failure(let error):
        print("[Get rewards] \(error.localizedDescription)")
        if error.code / 100 == 4 {
          // case error 4xx mean login token is expired, need update it
          self.updateLoginToken { completed in
            if completed {
              // recall loadRewards when new login token is updated
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.loadRewards()
              }
            }
          }
        }
      }
    }
  }

  func loadClaimRewards(shouldShowPopup: Bool = false) {
    guard let loginToken = Storage.retrieve(self.session.wallet.address.description + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        self.loadClaimRewards(shouldShowPopup: shouldShowPopup)
      }
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.session.wallet.address.description

    provider.request(.getClaimRewards(address: address, accessToken: loginToken.token)) { (result) in
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
          }
        }
        
      case .failure(let error):
        print("[Claim reward] \(error.localizedDescription)")
        if error.code / 100 == 4 {
          // case error 4xx mean login token is expired, need update it
          self.updateLoginToken { completed in
            if completed {
              // recall loadRewards when new login token is updated
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.loadClaimRewards(shouldShowPopup: shouldShowPopup)
              }
            }
          }
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
          print(hash)
          provider.minTxCount += 1
          let tx = transaction.toTransaction(hash: hash, fromAddr: self.session.wallet.address.description, type: .withdraw)
          self.session.addNewPendingTransaction(tx)
          let description = self.rootViewController.viewModel.totalBalanceString()
          let detailDescription = tx.to
          let historyTransaction = InternalHistoryTransaction(type: .claimReward, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: description, transactionDetailDescription: detailDescription, transactionObj: transaction.toSignTransactionObject())
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
        case .failure:
            print("Error")
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
    if let txHash = self.transactionStatusVC?.transaction.hash, txHash == tx.hash {
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
    // check eligible wallet
    guard let provider = self.session.externalProvider else {
      return
    }
    self.rootViewController.viewModel.shouldDisableClaim = true
    self.rootViewController.updateUI()
    controller.viewModel.shouldDisableClaimButton = true
    controller.updateUI()
    controller.showLoading()

    self.checkEligibleWallet { isEligible in
      if isEligible {
        self.getLatestNonce { (nonce) in
          let newTxObject = txObject.newTxObjectWithNonce(nonce: provider.minTxCount)
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
    print("")
  }
}
