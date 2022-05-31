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
import WalletConnectSwift
import BigInt
import TrustCore
import JSONRPCKit
import APIKit
import Result

class PoolInfo: Codable {
  var anyToken: String = ""
  var decimals: Int = 0
  var liquidity: String = ""
  var logoUrl: String = ""
  var name: String = ""
  var symbol: String = ""

  init(json: JSONDictionary) {
    self.anyToken = json["anyToken"] as? String ?? ""
    self.decimals = json["decimals"] as? Int ?? 0
    self.liquidity = json["liquidity"] as? String ?? ""
    self.logoUrl = json["logoUrl"] as? String ?? ""
    self.name = json["name"] as? String ?? ""
    self.symbol = json["symbol"] as? String ?? ""
  }
  
  func liquidityPoolString() -> String {
    let liquidity = Double(self.liquidity) ?? 0
    let displayLiquidity = liquidity / pow(10, self.decimals).doubleValue
    let displayLiquiditySring = StringFormatter.amountString(value: displayLiquidity)
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
      print(self)
    }
  }
}

protocol BridgeCoordinatorDelegate: class {
  func didSelectAddChainWallet(chainType: ChainType)
  func didSelectWallet(_ wallet: Wallet)
  func didSelectAddWallet()
  func didSelectManageWallet()

}

class BridgeCoordinator: NSObject, Coordinator {
  fileprivate var session: KNSession
  weak var delegate: BridgeCoordinatorDelegate?
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var data: [SourceBridgeToken] = []
  
  lazy var rootViewController: BridgeViewController = {
    let viewModel = BridgeViewModel(wallet: self.session.wallet)
    let controller = BridgeViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
    self.fetchData()
  }
  
  func fetchData() {
    self.getServerInfo(chainId: KNGeneralProvider.shared.currentChain.getChainId()) {
      if let address = self.rootViewController.viewModel.currentSourceToken?.address {
        self.getPoolInfo(chainId: KNGeneralProvider.shared.currentChain.getChainId(), tokenAddress: address) { poolInfo in
          if let poolInfo = poolInfo {
            self.rootViewController.viewModel.currentSourcePoolInfo = poolInfo
            self.rootViewController.viewModel.showFromPoolInfo = true
          }
          self.rootViewController.coordinatorDidUpdateData()
        }
      } else {
        self.rootViewController.coordinatorDidUpdateData()
      }
    }
  }

  func appCoordinatorDidUpdateChain() {
    self.rootViewController.viewModel = BridgeViewModel(wallet: self.session.wallet)
    self.rootViewController.coordinatorDidUpdateChain()
    self.fetchData()
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
  }
  
  func getServerInfo(chainId: Int, completion: @escaping (() -> Void)) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    self.rootViewController.showLoadingHUD()
    
    provider.request(.getServerInfo(chainId: chainId)) { result in
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
            
            var allTokens = KNSupportedTokenStorage.shared.getAllTokenObject()
              
            let supportedAddress = self.data.map { return $0.address.lowercased() }
            allTokens = allTokens.filter({
              supportedAddress.contains($0.address.lowercased())
            })
            self.rootViewController.viewModel.currentSourceToken = allTokens.first
          }
        }
      case .failure(let error):
        print("[Get Server Info] \(error.localizedDescription)")
      }
      completion()
    }
  }
  
  func getPoolInfo(chainId: Int, tokenAddress: String, completion: @escaping ((PoolInfo?) -> Void)) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    self.rootViewController.showLoadingHUD()
    
    provider.request(.getPoolInfo(chainId: chainId, tokenAddress: tokenAddress)) { result in
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
        completion(nil)
      }
    }
  }
}

extension BridgeCoordinator: BridgeViewControllerDelegate {
  func bridgeViewControllerController(_ controller: BridgeViewController, run event: BridgeEvent) {
    switch event {
    case .changeAmount(amount: let amount):
      self.rootViewController.viewModel.sourceAmount = amount
      self.rootViewController.coordinatorDidUpdateData()
    case .didSelectDestChain(chain: let newChain):
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
              self.rootViewController.viewModel.showToPoolInfo = true
              self.rootViewController.coordinatorDidUpdateData()
            }
          }
        }
      }
      self.rootViewController.coordinatorDidUpdateData()
    case .openHistory:
      print("")
    case .openWalletsList:
      let viewModel = WalletsListViewModel(
        walletObjects: KNWalletStorage.shared.availableWalletObjects,
        currentWallet: self.session.currentWalletObject
      )
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
    case .addChainWallet(let chainType):
      self.delegate?.didSelectAddChainWallet(chainType: chainType)
    case .willSelectDestChain:
      guard let sourceToken = self.rootViewController.viewModel.currentSourceToken else { return }
      let currentData = self.data.first {
        $0.address.lowercased() ==  sourceToken.address.lowercased()
      }
      guard let currentData = currentData else {
        return
      }
      let sourceChain = currentData.destChains.keys.map { key -> ChainType in
        let chainId = Int(key) ?? 0
        return ChainType.getAllChain().first { $0.getChainId() == chainId } ?? .eth
      }
      self.rootViewController.openSwitchChainPopup(sourceChain, false)
    case .selectSourceToken:
      var tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
        
      let supportedAddress = self.data.map { return $0.address.lowercased() }
      tokens = tokens.filter({
        supportedAddress.contains($0.address.lowercased())
      })
        
      let viewModel = KNSearchTokenViewModel(
        supportedTokens: tokens
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
    case .changeShowDestAddress:
      self.rootViewController.viewModel.showSendAddress = !self.rootViewController.viewModel.showSendAddress
      self.rootViewController.coordinatorDidUpdateData()
    case .changeDestAddress(address: let address):
      self.rootViewController.viewModel.currentSendToAddress = address
      self.rootViewController.coordinatorDidUpdateData()
    case .checkAllowance(token: let from):
      self.getAllowance(token: from)
    case .selectSwap:
      let viewModel = self.rootViewController.viewModel
      if let currentSourceToken = viewModel.currentSourceToken {
      let fromValue = "\(viewModel.sourceAmount) \(currentSourceToken.symbol)"
      let toValue = "\(viewModel.calculateDesAmount()) \(currentSourceToken.symbol)"
      let fee = "0.0253 ETH"

      let bridgeViewModel = ConfirmBridgeViewModel(fromChain: viewModel.currentSourceChain, fromValue: fromValue, fromAddress: self.session.wallet.addressString, toChain: viewModel.currentDestChain, toValue: toValue, toAddress: viewModel.currentSendToAddress, fee: fee)
      let vc = ConfirmBridgeViewController(viewModel: bridgeViewModel)
      self.navigationController.present(vc, animated: true, completion: nil)
      }
    case .sendApprove(token: let token, remain: let remain):
      let vc = ApproveTokenViewController(viewModel: ApproveTokenViewModelForTokenObject(token: token, res: remain))
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    }
  }
  
  func getAllowance(token: TokenObject) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getAllowance(token: token) { [weak self] getAllowanceResult in
      guard let `self` = self else { return }
      switch getAllowanceResult {
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
    data[self.session.wallet.addressString] = state
    UserDefaults.standard.setValue(data, forKey: Constants.useGasTokenDataKey)
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

extension BridgeCoordinator: ApproveTokenViewControllerDelegate {
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
        provider.sendApproveERCToken(for: token, value: Constants.maxValueBigInt, gasPrice: KNGasCoordinator.shared.defaultKNGas, gasLimit: gasLimit) { (result) in
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
  
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt) {
    self.navigationController.displayLoading()
    guard let provider = self.session.externalProvider, let gasTokenAddress = Address(string: address) else {
      return
    }
    provider.sendApproveERCTokenAddress(
      for: gasTokenAddress,
      value: Constants.maxValueBigInt,
      gasPrice: KNGasCoordinator.shared.defaultKNGas,
      gasLimit: gasLimit
    ) { approveResult in
      self.navigationController.hideLoading()
      switch approveResult {
      case .success:
        self.saveUseGasTokenState(state)
//        self.rootViewController.coordinatorUpdateIsUseGasToken(state)
//        self.gasFeeSelectorVC?.coordinatorDidUpdateUseGasTokenState(state)
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
//        self.rootViewController.coordinatorUpdateIsUseGasToken(!state)
//        self.gasFeeSelectorVC?.coordinatorDidUpdateUseGasTokenState(!state)
      }
    }
  }
  
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: Address) {
    guard case .real(let account) = self.session.wallet.type else {
      return
    }
    KNGeneralProvider.shared.buildSignTxForApprove(tokenAddress: tokenAddress, account: account) { signTx in
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
      self.getAllowance(token: token)
      self.rootViewController.coordinatorDidUpdateData()
    default:
      return
    }
  }
}

extension BridgeCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.didSelectManageWallet()
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
      self.delegate?.didSelectWallet(wal)
    case .addWallet:
      self.delegate?.didSelectAddWallet()
    }
  }
}

extension BridgeCoordinator: QRCodeReaderDelegate {
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
