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

class DestBridgeToken: Codable {
  var address: String = ""
  var name: String = ""
  var symbol: String = ""
  var decimals: Int = 0
  var maximumSwap: Double = 0.0
  var minimumSwap: Double = 0.0
  
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
    self.maximumSwap = json["maximumSwap"] as? Double ?? 0.0
    self.minimumSwap = json["minimumSwap"] as? Double ?? 0.0
  }
}

class SourceBridgeToken: Codable {
  var address: String = ""
  var name: String = ""
  var symbol: String = ""
  var decimals: Int = 0
  var destChains: [String : DestBridgeToken] = [:]
  
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
    
    self.getServerInfo(chainId: KNGeneralProvider.shared.currentChain.getChainId()) {
      self.rootViewController.coordinatorDidUpdateData()
    }
  }
  
  func appCoordinatorDidUpdateChain() {
    self.rootViewController.viewModel = BridgeViewModel(wallet: self.session.wallet)
    self.rootViewController.coordinatorDidUpdateChain()
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
          }
        }
      case .failure(let error):
        print("[Get Server Info] \(error.localizedDescription)")
      }
      completion()
    }
  }
}

extension BridgeCoordinator: BridgeViewControllerDelegate {
  func bridgeViewControllerController(_ controller: BridgeViewController, run event: BridgeEvent) {
    switch event {
    case .switchChain:
      print("")
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
    case .selectDestChain:
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
    }
  }
}

extension BridgeCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true, completion: nil)
    switch event {
    case .select(let token):
      self.rootViewController.viewModel.currentSourceToken = token
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
