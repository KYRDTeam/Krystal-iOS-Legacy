//
//  BridgeCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit
import Moya
import MBProgressHUD
import QRCodeReaderViewController
import BigInt
import JSONRPCKit
import APIKit
import Result
import KrystalWallets

class PoolInfo: Codable {
  var anyToken: String = ""
  var decimals: Int = 0
  var liquidity: String = ""
  var logoUrl: String = ""
  var name: String = ""
  var symbol: String = ""
  var isUnlimited: Bool = false

  init(json: JSONDictionary) {
    self.anyToken = json["anyToken"] as? String ?? ""
    self.decimals = json["decimals"] as? Int ?? 0
    self.liquidity = json["liquidity"] as? String ?? ""
    self.logoUrl = json["logoUrl"] as? String ?? ""
    self.name = json["name"] as? String ?? ""
    self.symbol = json["symbol"] as? String ?? ""
    self.isUnlimited = json["isUnlimited"] as? Bool ?? false
  }
  
  func liquidityPoolString() -> String {
    let liquidity = Double(self.liquidity) ?? 0
    var displayLiquidity = liquidity / pow(10, self.decimals).doubleValue
    let currencyFormatter = StringFormatter()
    let displayLiquiditySring = currencyFormatter.currencyString(value: displayLiquidity, decimals: 0)
    return " Pool: \(displayLiquiditySring) \(self.symbol)"
  }
}

class DestBridgeToken: Codable {
  var address: String = ""
  var name: String = ""
  var symbol: String = ""
  var decimals: Int = 0
  var maximumSwap: Double = 0.0
  var minimumSwap: Double = 0.0
  var bigValueThreshold: Double = 0.0
  var swapFeeRatePerMillion: Double = 0.0
  var maximumSwapFee: Double = 0.0
  var minimumSwapFee: Double = 0.0
  
  init(json: JSONDictionary) {
    if let underlyingJson = json["underlying"] as? JSONDictionary {
      self.address = underlyingJson["address"] as? String ?? ""
      self.name = underlyingJson["name"] as? String ?? ""
      self.symbol = underlyingJson["symbol"] as? String ?? ""
      self.decimals = underlyingJson["decimals"] as? Int ?? 0
    }
    if self.address.isEmpty {
      // incase underlying empty the current token will be anyToken
      if let anyTokenJson = json["anyToken"] as? JSONDictionary {
        self.address = anyTokenJson["address"] as? String ?? ""
        self.name = anyTokenJson["name"] as? String ?? ""
        self.symbol = anyTokenJson["symbol"] as? String ?? ""
        self.decimals = anyTokenJson["decimals"] as? Int ?? 0
      }
    }
    
    self.maximumSwap = Double(json["maximumSwap"] as? String ?? "0.0") ?? 0
    self.minimumSwap = Double(json["minimumSwap"] as? String ?? "0.0") ?? 0
    self.bigValueThreshold = Double(json["bigValueThreshold"] as? String ?? "0.0") ?? 0
    self.swapFeeRatePerMillion = json["swapFeeRatePerMillion"] as? Double ?? 0.0
    self.maximumSwapFee = Double(json["maximumSwapFee"] as? String ?? "0.0") ?? 0
    self.minimumSwapFee = Double(json["minimumSwapFee"] as? String ?? "0.0") ?? 0
  }
}

class SourceBridgeToken: Codable {
  var address: String = ""
  var name: String = ""
  var symbol: String = ""
  var logoUrl: String = ""
  var decimals: Int = 0
  var destChains: [String: DestBridgeToken] = [:]
  
  init(json: JSONDictionary) {
    if let underlyingJson = json["underlying"] as? JSONDictionary {
      self.address = underlyingJson["address"] as? String ?? ""
      self.name = underlyingJson["name"] as? String ?? ""
      self.symbol = underlyingJson["symbol"] as? String ?? ""
      self.decimals = underlyingJson["decimals"] as? Int ?? 0
    }
    if self.address.isEmpty {
      // incase underlying empty the current token will be anyToken
      if let anyTokenJson = json["anyToken"] as? JSONDictionary {
        self.address = anyTokenJson["address"] as? String ?? ""
        self.name = anyTokenJson["name"] as? String ?? ""
        self.symbol = anyTokenJson["symbol"] as? String ?? ""
        self.decimals = anyTokenJson["decimals"] as? Int ?? 0
      }
    }
    
    if let destChainsJson = json["destChains"] as? JSONDictionary {
      for key in destChainsJson.keys {
        if let destBridgeTokenJson = destChainsJson[key] as? JSONDictionary {
          let destBridgeToken = DestBridgeToken(json: destBridgeTokenJson)
          self.destChains[key] = destBridgeToken
        }
      }
    }

    self.logoUrl = json["logoUrl"] as? String ?? ""
  }
}

protocol BridgeCoordinatorDelegate: class {
  func didSelectAddChainWallet(chainType: ChainType)
  func didSelectOpenHistoryList()
}

class BridgeCoordinator: NSObject, Coordinator {
  weak var delegate: BridgeCoordinatorDelegate?
  var historyCoordinator: KNHistoryCoordinator?
  
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var data: [SourceBridgeToken] = []

  var advancedGasLimit: String?
  var advancedMaxPriorityFee: String?
  var advancedMaxFee: String?
  var advancedNonce: String?
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }

  fileprivate(set) var currentSignTransaction: SignTransaction?
  fileprivate(set) var bridgeContract: String = ""
  fileprivate(set) var minRatePercent: Double = 0.5
  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var isOpenGasSettingForApprove: Bool = false
  
    @FileStorage(fileName: Constants.bridgeWarningSettingFile, defaultValue: UserDefaults.standard.bool(forKey: Constants.bridgeWarningAcceptedKey))
    var bridgeWaringAccepted: Bool
  
  lazy var rootViewController: BridgeViewController = {
    let viewModel = BridgeViewModel()
    let controller = BridgeViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()
  
  var confirmVC: ConfirmBridgeViewController?
  var approveVC: ApproveTokenViewController?
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: {
      if !self.bridgeWaringAccepted {
        let alertController = KNPrettyAlertController(
          title: Strings.warningTitle,
          isWarning: true,
          message: Strings.bridgeWarningText,
          secondButtonTitle: Strings.understand,
          firstButtonTitle: Strings.goBack,
          secondButtonAction: {
            self.bridgeWaringAccepted = true
          },
          firstButtonAction: {
            self.navigationController.popViewController(animated: true, completion: nil)
          }
        )
        alertController.popupHeight = 350
        self.navigationController.present(alertController, animated: true, completion: nil)
        MixPanelManager.track("bridge_warning_pop_up_open", properties: ["screenid": "bridge_warning_pop_up"])
      }
    })
    self.fetchData()
  }
  
  func fetchData(completion: (() -> Void)? = nil) {
    self.getServerInfo(chainId: KNGeneralProvider.shared.currentChain.getChainId()) {
      if let address = self.rootViewController.viewModel.currentSourceToken?.address {
        self.getPoolInfo(chainId: KNGeneralProvider.shared.currentChain.getChainId(), tokenAddress: address) { poolInfo in
          if let poolInfo = poolInfo {
            self.rootViewController.viewModel.currentSourcePoolInfo = poolInfo
            self.rootViewController.viewModel.showFromPoolInfo = poolInfo.isUnlimited == false
          }
          self.rootViewController.coordinatorDidUpdateData()
          if let completion = completion {
            completion()
          }
        }
      } else {
        self.rootViewController.coordinatorDidUpdateData()
        if let completion = completion {
          completion()
        }
      }
    }
  }

  func appCoordinatorDidUpdateChain() {
    self.gasPrice = KNGasCoordinator.shared.standardKNGas
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
    self.selectedGasPriceType = .medium
    self.rootViewController.viewModel = BridgeViewModel()
    self.rootViewController.coordinatorDidUpdateChain()
    self.fetchData()
  }
  
  func appCoordinatorSwitchAddress() {
    self.gasPrice = KNGasCoordinator.shared.standardKNGas
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
    self.selectedGasPriceType = .medium
    self.rootViewController.appDidSwitchAddress()
    self.fetchData()
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.rootViewController.coordinatorDidUpdatePendingTx()
  }
  
  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if tx.state == .pending {
      return false
    }
    self.rootViewController.coordinatorDidSuccessApprove(state: tx.state)
    return true
  }
  
  func getServerInfo(chainId: Int, completion: @escaping (() -> Void)) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    self.rootViewController.showLoadingHUD()
    self.data = []
    provider.requestWithFilter(.getServerInfo(chainId: chainId)) { result in
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      var tokens: [SourceBridgeToken] = []
      switch result {
      case .success(let result):
        if let json = try? result.mapJSON() as? JSONDictionary ?? [:], let data = json["data"] as? [JSONDictionary] {
          for dataJson in data {
            let sourceBridgeToken = SourceBridgeToken(json: dataJson)
            tokens.append(sourceBridgeToken)
          }
          if tokens.isNotEmpty {
            self.data = tokens
          }
        }
      case .failure(let error):
        self.showWarningTopBannerMessage(
          with: "",
          message: error.localizedDescription,
          time: 2.0
        )
      }
      completion()
    }
  }
  
  func getPoolInfo(chainId: Int, tokenAddress: String, completion: @escaping ((PoolInfo?) -> Void)) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    self.rootViewController.showLoadingHUD()
    provider.requestWithFilter(.getPoolInfo(chainId: chainId, tokenAddress: tokenAddress)) { result in
      DispatchQueue.main.async {
        self.rootViewController.hideLoading()
      }
      switch result {
      case .success(let result):
        if let json = try? result.mapJSON() as? JSONDictionary ?? [:] {
          let poolInfo = PoolInfo(json: json)
          completion(poolInfo)
        } else {
          completion(nil)
        }
      case .failure(let error):
        self.showWarningTopBannerMessage(
          with: "",
          message: error.localizedDescription,
          time: 2.0
        )
        completion(nil)
      }
    }
  }
  
  func buildSwapChainTx(completion: @escaping ((TxObject?) -> Void)) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    let fromAddress = self.currentAddress.addressString
    let toAddress = self.rootViewController.viewModel.currentSendToAddress
    let fromChainId = self.rootViewController.viewModel.currentSourceChain?.getChainId() ?? 0
    let toChainId = self.rootViewController.viewModel.currentDestChain?.getChainId() ?? 0
    let tokenAddress = self.rootViewController.viewModel.currentSourceToken?.address ?? ""
    
    let decimal = self.rootViewController.viewModel.currentSourceToken?.decimals ?? 0
    
    let amount = self.rootViewController.viewModel.sourceAmount.amountBigInt(decimals: decimal) ?? BigInt(0)
    let amountString = amount.description
    
    provider.requestWithFilter(.buildSwapChainTx(fromAddress: fromAddress, toAddress: toAddress, fromChainId: fromChainId, toChainId: toChainId, tokenAddress: tokenAddress, amount: amountString)) { result in
      if case .success(let resp) = result {
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(TransactionResponse.self, from: resp.data)
          completion(data.txObject)
          
        } catch let error {
          self.navigationController.showTopBannerView(message: error.localizedDescription)
        }
      } else {
        self.navigationController.showTopBannerView(message: "Build Tx request is failed")
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
    return data[self.currentAddress.addressString] ?? false
  }
  
  fileprivate func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
    guard !KNGeneralProvider.shared.isBrowsingMode else { return }
    let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
    web3Service.getTransactionCount(for: currentAddress.addressString) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  fileprivate func buildSignTx(_ object: TxObject) -> SignTransaction? {
    guard
      let value = BigInt(object.value.drop0x, radix: 16),
      var gasPrice = BigInt(object.gasPrice.drop0x, radix: 16),
      var gasLimit = BigInt(object.gasLimit.drop0x, radix: 16),
      
        // sai o day nay
      var nonce = Int(object.nonce.drop0x, radix: 16)
    else
    {
      return nil
    }
    
    if let unwrap = self.advancedMaxFee, let value = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      gasPrice = value
    }

    if let unwrap = self.advancedGasLimit, let value = BigInt(unwrap) {
      gasLimit = value
    }

    if let unwrap = self.advancedNonce, let value = Int(unwrap) {
      nonce = value
    }
    
    return SignTransaction(
      value: value,
      address: currentAddress.addressString,
      to: object.to,
      nonce: nonce,
      data: Data(hex: object.data.drop0x),
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  
  func pullToRefresh() {
    self.fetchData {
      self.rootViewController.isRefreshingTableView = false
      self.rootViewController.refreshControl.endRefreshing()
    }
  }
}

extension BridgeCoordinator: BridgeViewControllerDelegate {
  
  func didSelectDestChain(newChain: ChainType) {
    self.rootViewController.viewModel.currentDestChain = newChain
    self.rootViewController.viewModel.showReminder = true
    if let currentSourceToken = self.rootViewController.viewModel.currentSourceToken {
      if let currentBridgeToken = self.data.first(where: { $0.address.lowercased() == currentSourceToken.address.lowercased()
      }) {
        let currentDestChainToken = currentBridgeToken.destChains[newChain.getChainId().toString()]
        self.rootViewController.viewModel.currentDestToken = currentDestChainToken

        if let address = currentDestChainToken?.address {
          self.getPoolInfo(chainId: newChain.getChainId(), tokenAddress: address) { poolInfo in
            self.rootViewController.viewModel.currentDestPoolInfo = poolInfo
            self.rootViewController.viewModel.showToPoolInfo = poolInfo?.isUnlimited == false
            self.rootViewController.coordinatorDidUpdateData()
          }
        }
      }
    }
    self.getBuildTx()
    self.rootViewController.coordinatorDidUpdateData()
  }
  
  func currentDestChains() -> [ChainType]? {
    guard let sourceToken = self.rootViewController.viewModel.currentSourceToken else { return nil }
    let currentData = self.data.first {
      $0.address.lowercased() ==  sourceToken.address.lowercased()
    }
    guard let currentData = currentData else {
      return nil
    }
    let sourceChain = currentData.destChains.keys.map { key -> ChainType in
      let chainId = Int(key) ?? 0
      return ChainType.getAllChain().first { $0.getChainId() == chainId } ?? .eth
    }
    return sourceChain
  }
  
  func willSelectDestChain() {
    if let destChains = self.currentDestChains() {
      self.rootViewController.openSwitchChainPopup(destChains, false)
    }
  }
  
  func bridgeViewControllerController(_ controller: BridgeViewController, run event: BridgeEvent) {
    switch event {
    case .pullToRefresh:
      self.pullToRefresh()
    case .changeAmount(amount: let amount):
      self.rootViewController.viewModel.sourceAmount = amount
      self.rootViewController.coordinatorDidUpdateData()
    case .didSelectDestChain(chain: let newChain):
      self.didSelectDestChain(newChain: newChain)
    case .openHistory:
        self.delegate?.didSelectOpenHistoryList()
    case .addChainWallet(let chainType):
      self.delegate?.didSelectAddChainWallet(chainType: chainType)
    case .willSelectDestChain:
      self.willSelectDestChain()
    case .selectSourceToken:
//      var tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
//      let supportedAddress = self.data.map { return $0.address.lowercased() }
//      tokens = tokens.filter({
//        supportedAddress.contains($0.address.lowercased())
//      })
        
      let supportedTokens = self.data.map { sourceBridgeToken -> TokenObject in
        let token = TokenObject(name: sourceBridgeToken.name, symbol: sourceBridgeToken.symbol, address: sourceBridgeToken.address, decimals: sourceBridgeToken.decimals, logo: sourceBridgeToken.logoUrl)
        return token
      }
        
      let viewModel = KNSearchTokenViewModel(
        supportedTokens: supportedTokens
      )
      let controller = KNSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.rootViewController.present(controller, animated: true, completion: nil)
    case .selectDestToken:
      let tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
      let viewModel = KNSearchTokenViewModel(
        supportedTokens: tokens
      )
      let controller = KNSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.rootViewController.present(controller, animated: true, completion: nil)
    case .changeDestAddress(address: let address):
      self.rootViewController.viewModel.currentSendToAddress = address
      self.rootViewController.coordinatorDidUpdateData()
    case .checkAllowance(token: let from):
      self.getAllowance(token: from)
    case .selectSwap:
      self.navigationController.displayLoading()
      self.getBuildTx {
        self.navigationController.hideLoading()
        let viewModel = self.rootViewController.viewModel
        if let currentSourceToken = viewModel.currentSourceToken {
          let fromValue = "\(viewModel.sourceAmount) \(currentSourceToken.symbol)"
          let toValue = "\(viewModel.calculateDesAmountString()) \(viewModel.currentDestToken?.symbol ?? currentSourceToken.symbol)"
          var bridgeFeeString = ""
          let viewModel = self.rootViewController.viewModel
          if let currentDestToken = viewModel.currentDestToken {
            bridgeFeeString = StringFormatter.amountString(value: currentDestToken.minimumSwapFee) + " \(currentSourceToken.symbol)"
          }

          let bridgeViewModel = ConfirmBridgeViewModel(fromChain: viewModel.currentSourceChain, fromValue: fromValue, fromAddress: self.currentAddress.addressString, toChain: viewModel.currentDestChain, toValue: toValue, toAddress: viewModel.currentSendToAddress, bridgeFee: bridgeFeeString, token: currentSourceToken, gasPrice: self.gasPrice, gasLimit: self.estimateGasLimit, signTransaction: self.currentSignTransaction, eip1559Transaction: nil)
          let vc = ConfirmBridgeViewController(viewModel: bridgeViewModel)
          vc.delegate = self
          self.confirmVC = vc
          self.navigationController.present(vc, animated: true, completion: nil)
        }
      }
    case .sendApprove(token: let token, remain: let remain, value: let value):
      let vm = ApproveTokenViewModelForTokenObject(token: token, res: remain)
      vm.value = value
      vm.showEditSettingButton = true
      vm.headerTitle = "Approve Transfer"
      let vc = ApproveTokenViewController(viewModel: vm)
      vc.delegate = self
      vc.onDismiss = {
        self.rootViewController.coordinatorCancelApprove()
      }
      self.navigationController.present(vc, animated: true, completion: nil)
      self.approveVC = vc
    case .selectMaxSource:
      guard let from = self.rootViewController.viewModel.currentSourceToken else { return }
      if from.isQuoteToken {
        let balance = from.getBalanceBigInt()
        let fee = self.gasPrice * self.estimateGasLimit
        if balance <= fee {
          self.rootViewController.viewModel.sourceAmount = 0
        }
        
        let availableToSwap = max(BigInt(0), balance - fee)
        let doubleValue = availableToSwap.string(
          decimals: from.decimals,
          minFractionDigits: 0,
          maxFractionDigits: min(from.decimals, 5)
        ).doubleValue
        self.rootViewController.viewModel.sourceAmount = doubleValue
      } else {
        let bal: BigInt = from.getBalanceBigInt()
        let doubleValue = bal.string(
          decimals: from.decimals,
          minFractionDigits: 0,
          maxFractionDigits: min(from.decimals, 5)
        ).doubleValue
        self.rootViewController.viewModel.sourceAmount = doubleValue
      }
      self.rootViewController.coordinatorDidUpdateData()
    case .scanAddress:
        if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self.rootViewController) {
        return
      }
      let qrcodeReaderVC: QRCodeReaderViewController = {
        let controller = QRCodeReaderViewController()
        controller.delegate = self
        return controller
      }()
      self.rootViewController.present(qrcodeReaderVC, animated: true, completion: nil)
    }
  }
  
  func estimateGasForApprove(tokenAddress: String, value: BigInt, completion: @escaping (BigInt) -> Void) {
    KNGeneralProvider.shared.getSendApproveERC20TokenEncodeData(networkAddress: bridgeContract, value: value) { encodeResult in
      switch encodeResult {
      case .success(let data):
        let setting = ConfirmAdvancedSetting(
          gasPrice: KNGasCoordinator.shared.defaultKNGas.description,
          gasLimit: KNGasConfiguration.approveTokenGasLimitDefault.description,
          advancedGasLimit: nil,
          advancedPriorityFee: nil,
          avancedMaxFee: nil,
          advancedNonce: nil
        )
        if KNGeneralProvider.shared.isUseEIP1559 {
          let tx = TransactionFactory.buildEIP1559Transaction(from: self.currentAddress.addressString, to: tokenAddress, nonce: 1, data: data, setting: setting)
          KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: tx) { result in
            switch result {
            case .success(let estGas):
              completion(estGas)
            case .failure(_):
              completion(KNGasConfiguration.approveTokenGasLimitDefault)
            }
          }
        } else {
          let tx = TransactionFactory.buildLegacyTransaction(address: self.currentAddress.addressString, to: tokenAddress, nonce: 1, data: data, setting: setting)
          KNGeneralProvider.shared.getEstimateGasLimit(transaction: tx) { result in
            switch result {
            case .success(let estGas):
              completion(estGas)
            case .failure(_):
              completion(KNGasConfiguration.approveTokenGasLimitDefault)
            }
          }
        }
      case .failure( _):
        completion(KNGasConfiguration.approveTokenGasLimitDefault)
      }
    }
  }
  
  func getBuildTx(_ completion: (() -> Void)? = nil) {
    self.getLatestNonce { result in
      switch result {
      case .success(let nonce):
        self.buildSwapChainTx { txObject in
          if let txObject = txObject {
            let viewModel = self.rootViewController.viewModel
            let newTxObject = TxObject(nonce: BigInt(nonce).hexEncoded, from: txObject.from, to: txObject.to, data: txObject.data, value: txObject.value, gasPrice: self.gasPrice.hexEncoded, gasLimit: txObject.gasLimit)
            self.bridgeContract = txObject.to
            guard let signTx = self.buildSignTx(newTxObject) else {
              if let completion = completion {
                completion()
              }
              return
            }
            self.currentSignTransaction = signTx
            self.estimateGasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? KNGasConfiguration.exchangeTokensGasLimitDefault
            self.getAllowance(token: viewModel.currentSourceToken)
            if let completion = completion {
              completion()
            }
          }
        }
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(message: error.description)
      }
    }
  }
  
  func getAllowance(token: TokenObject?) {
    guard let token = token else {
      return
    }
    guard !self.bridgeContract.isEmpty else {
      return
    }
    let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
    web3Service.getAllowance(for: currentAddress.addressString, networkAddress: bridgeContract, tokenAddress: token.address) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let res):
        self.rootViewController.coordinatorDidUpdateAllowance(token: token, allowance: res)
      case .failure:
        self.rootViewController.coordinatorDidFailUpdateAllowance(token: token)
      }
    }
  }
  
  fileprivate func saveUseGasTokenState(_ state: Bool) {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    }
    data[self.currentAddress.addressString] = state
    UserDefaults.standard.setValue(data, forKey: Constants.useGasTokenDataKey)
  }
  
  fileprivate func resetAllowanceForTokenIfNeeded(_ token: TokenObject, remain: BigInt, gasLimit: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    if remain.isZero {
      completion(.success(true))
      return
    }
    let gasPrice = KNGasCoordinator.shared.defaultKNGas
    let processor = EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
    processor.sendApproveERCTokenAddress(owner: self.currentAddress, tokenAddress: token.contract, value: BigInt(0), gasPrice: gasPrice, gasLimit: gasLimit, toAddress: bridgeContract) { result in
      switch result {
      case .success:
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

extension BridgeCoordinator: ConfirmBridgeViewControllerDelegate {
  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = BridgeTransactionStatusPopup(transaction: transaction)
    self.navigationController.present(controller, animated: true, completion: nil)

  }
  
  func didConfirm(_ controller: ConfirmBridgeViewController, signTransaction: SignTransaction, internalHistoryTransaction: InternalHistoryTransaction) {
    self.navigationController.displayLoading()
    self.getBuildTx {
      let viewModel = self.rootViewController.viewModel
      guard let sourceToken = viewModel.currentSourceToken, let sourceChain = viewModel.currentSourceChain,
            let destToken = viewModel.currentDestToken, let destChain = viewModel.currentDestChain else {
        return
      }
      let ethTxSigner = EthereumTransactionSigner()
      let signResult = ethTxSigner.signTransaction(address: self.currentAddress, transaction: self.currentSignTransaction ?? signTransaction)
      switch signResult {
      case .success(let signedData):
        KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
          self.navigationController.hideLoading()
          switch sendResult {
          case .success(let hash):
            NonceCache.shared.increaseNonce(address: self.currentAddress.addressString, chain: KNGeneralProvider.shared.currentChain)
            internalHistoryTransaction.hash = hash
            internalHistoryTransaction.nonce = signTransaction.nonce
            internalHistoryTransaction.time = Date()
            
            let extraData = InternalHistoryExtraData(
              from: ExtraBridgeTransaction(
                address: signTransaction.address,
                token: sourceToken.symbol,
                amount: viewModel.sourceAmount.amountBigInt(decimals: sourceToken.decimals) ?? BigInt(0),
                chainId: sourceChain.getChainId().toString(),
                chainName: sourceChain.chainName(),
                tx: hash,
                txStatus: "PENDING",
                decimals: sourceToken.decimals
              ),
              to: ExtraBridgeTransaction(
                address: viewModel.currentSendToAddress,
                token: destToken.symbol,
                amount: viewModel.estimatedDestAmount,
                chainId: destChain.getChainId().toString(),
                chainName: destChain.chainName(),
                tx: "",
                txStatus: "PENDING",
                decimals: sourceToken.decimals
              ),
              type: "crosschain",
              crosschainStatus: "PENDING"
            )
            
            internalHistoryTransaction.extraData = extraData
            AppDelegate.session.crosschainTxService.addPendingTxHash(txHash: hash)
            EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalHistoryTransaction)
            controller.dismiss(animated: true) {
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
  }
  
  func didConfirm(_ controller: ConfirmBridgeViewController, eip1559Tx: EIP1559Transaction, internalHistoryTransaction: InternalHistoryTransaction) {
    
  }

  func openGasPriceSelect() {
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: self.estimateGasLimit, selectType: self.selectedGasPriceType, currentRatePercentage: self.minRatePercent, isUseGasToken: self.isAccountUseGasToken(), isContainSlippageSection: false)

    viewModel.baseGasLimit = self.estimateGasLimit
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    viewModel.advancedGasLimit = self.advancedGasLimit
    viewModel.advancedMaxPriorityFee = self.advancedMaxPriorityFee
    viewModel.advancedMaxFee = self.advancedMaxFee
    viewModel.advancedNonce = self.advancedNonce
    self.isOpenGasSettingForApprove = false
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.confirmVC?.present(vc, animated: true, completion: nil)
    self.getLatestNonce { result in
      switch result {
      case .success(let nonce):
        vc.coordinatorDidUpdateCurrentNonce(nonce)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(message: error.description)
      }
    }
  }
}

extension BridgeCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      if self.isOpenGasSettingForApprove {
        self.approveVC?.coordinatorDidUpdateGasPriceType(type, value: value)
      } else {
        self.advancedGasLimit = nil
        self.advancedMaxPriorityFee = nil
        self.advancedMaxFee = nil
        self.selectedGasPriceType = type
        self.gasPrice = value
        self.confirmVC?.coordinatorDidUpdateFee(gasPrice: self.gasPrice, gasLimit: self.estimateGasLimit)
      }
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
    case .updateAdvancedSetting(let gasLimit, let maxPriorityFee, let maxFee):
      if self.isOpenGasSettingForApprove {
        self.approveVC?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
      } else {
        self.advancedGasLimit = gasLimit
        self.advancedMaxPriorityFee = maxPriorityFee
        self.advancedMaxFee = maxFee
        self.selectedGasPriceType = .custom
        if let advancedMaxFee = self.advancedMaxFee, let gasPrice = advancedMaxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit), let advancedGasLimit = self.advancedGasLimit, let gasLimit = BigInt(advancedGasLimit) {
          self.confirmVC?.coordinatorDidUpdateFee(gasPrice: gasPrice, gasLimit: gasLimit)
        }
      }
    case .updateAdvancedNonce(let nonce):
      if self.isOpenGasSettingForApprove {
        self.approveVC?.coordinatorDidUpdateAdvancedNonce(nonce)
      } else {
        self.advancedNonce = nonce
      }
    default:
      break
    }
  }
}

extension BridgeCoordinator: ApproveTokenViewControllerDelegate {
  func approveTokenViewControllerDidSelectGasSetting(_ controller: ApproveTokenViewController, gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) {
    self.openGasPriceSelectView(gasLimit, selectType, baseGasLimit, advancedGasLimit, advancedPriorityFee, advancedMaxFee, advancedNonce, controller)
  }
  
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt, gasLimit: BigInt) {
    self.navigationController.displayLoading()
    self.resetAllowanceForTokenIfNeeded(token, remain: remain, gasLimit: gasLimit) { [weak self] resetResult in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch resetResult {
      case .success:
        let sourceTokenAddress = self.rootViewController.viewModel.currentSourceToken?.address ?? ""
        EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain).sendApproveERCTokenAddress(
          owner: self.currentAddress,
          tokenAddress: sourceTokenAddress,
          value: controller.approveValue,
          gasPrice: controller.selectedGasPrice,
          gasLimit: gasLimit,
          toAddress: self.bridgeContract) { result in
            switch result {
            case .success:
              // TODO show loading approve here
              self.rootViewController.coordinatorStartApprove(token: token)
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
  
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt) {
    self.navigationController.displayLoading()
    EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain).sendApproveERCTokenAddress(
      owner: self.currentAddress,
      tokenAddress: address,
      value: controller.approveValue,
      gasPrice: KNGasCoordinator.shared.defaultKNGas,
      gasLimit: gasLimit
    ) { approveResult in
      self.navigationController.hideLoading()
      switch approveResult {
      case .success:
        self.saveUseGasTokenState(state)
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
    }
  }
  
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: String, value: BigInt) {
    self.estimateGasForApprove(tokenAddress: tokenAddress, value: value) { estGas in
      controller.coordinatorDidUpdateGasLimit(estGas)
    }
  }
  
  fileprivate func openGasPriceSelectView(_ gasLimit: BigInt, _ selectType: KNSelectedGasPriceType, _ baseGasLimit: BigInt, _ advancedGasLimit: String?, _ advancedPriorityFee: String?, _ advancedMaxFee: String?, _ advancedNonce: String?, _ controller: UIViewController) {
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: false, gasLimit: gasLimit, selectType: selectType, isContainSlippageSection: false)
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
    self.isOpenGasSettingForApprove = true
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    
    self.getLatestNonce { result in
      switch result {
      case .success(let nonce):
        vc.coordinatorDidUpdateCurrentNonce(nonce)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(message: error.description)
      }
    }
    
    controller.present(vc, animated: true, completion: nil)
  }
}

extension BridgeCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true, completion: nil)
    switch event {
    case .select(let token):
      self.rootViewController.viewModel.currentSourceToken = token
      self.rootViewController.viewModel.sourceAmount = 0.0
      self.rootViewController.viewModel.currentDestChain = nil
      self.rootViewController.viewModel.currentDestToken = nil
      self.rootViewController.viewModel.currentDestPoolInfo = nil
      self.rootViewController.viewModel.showToPoolInfo = false
      self.rootViewController.viewModel.showReminder = false
      if let currentSourceChain = self.rootViewController.viewModel.currentSourceChain {
        self.getPoolInfo(chainId: currentSourceChain.getChainId(), tokenAddress: token.address) { poolInfo in
          self.rootViewController.viewModel.currentSourcePoolInfo = poolInfo
          self.rootViewController.viewModel.showFromPoolInfo = poolInfo?.isUnlimited == false
          self.rootViewController.coordinatorDidUpdateData()
        }
      }
      if let destChains = self.currentDestChains() {
        var selectedDestChain: ChainType? = nil
        if self.rootViewController.viewModel.currentSourceChain == .bsc {
          selectedDestChain = destChains.contains(.polygon) ? .polygon : destChains.first
        } else if self.rootViewController.viewModel.currentSourceChain == .polygon {
          selectedDestChain = destChains.contains(.bsc) ? .bsc : destChains.first
        } else {
          selectedDestChain = destChains.contains(.bsc) ? .bsc : (destChains.contains(.polygon) ? .polygon : destChains.first)
        }
        if let selectedDestChain = selectedDestChain {
          self.didSelectDestChain(newChain: selectedDestChain)
        }
      }
      self.rootViewController.coordinatorDidUpdateData()
    default:
      return
    }
  }
}

extension BridgeCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      let address: String = {
        if result.count < 42 { return result }
        if result.starts(with: "0x") { return result }
        let string = "\(result.suffix(42))"
        if string.starts(with: "0x") { return string }
        return result
      }()
      self.rootViewController.viewModel.currentSendToAddress = address
      self.rootViewController.coordinatorDidUpdateData()
    }
  }
}
