//
//  AppRouter.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import EarnModule
import Dependencies
import UIKit
import KrystalWallets
import AppState
import TokenModule

class AppRouter: AppRouterProtocol, Coordinator {
  
  var coordinators: [Coordinator] = []
  var historyCoordinator: Coordinator?
    
  func start() {
    fatalError("Do not use this function")
  }
  
  func openAddWallet() {
    guard let parent = UIApplication.shared.topMostViewController() else { return }
    let coordinator = KNAddNewWalletCoordinator(parentViewController: parent)
    coordinator.start(type: .full)
    coordinate(coordinator: coordinator)
  }
  
  func openWalletList(currentChain: ChainType,
                      allowAllChainOption: Bool,
                      onSelectWallet: @escaping (KWallet) -> Void,
                      onSelectWatchAddress: @escaping (KAddress) -> Void) {
    let walletsList = WalletListV2ViewController()
    walletsList.allowAllChainOption = allowAllChainOption
    walletsList.onSelectWallet = onSelectWallet
    walletsList.onSelectWatchAddress = onSelectWatchAddress
    let navigation = UINavigationController(rootViewController: walletsList)
    navigation.setNavigationBarHidden(true, animated: false)
    UIApplication.shared.topMostViewController()?.present(navigation, animated: true, completion: nil)
  }
  
    func openChainList(_ selectedChain: ChainType, allowAllChainOption: Bool, showSolanaOption: Bool, onSelectChain: @escaping (ChainType) -> Void) {
    MixPanelManager.track("import_select_chain_open", properties: ["screenid": "import_select_chain"])
    let popup = SwitchChainViewController(selected: selectedChain)
    var chains = WalletManager.shared.getAllAddresses(walletID: AppState.shared.currentAddress.walletID).flatMap { address in
      return ChainType.getAllChain().filter { chain in
        return chain != .all && chain.addressType == address.addressType
      }
    }
    if allowAllChainOption {
      chains = [.all] + chains
    }
    if !showSolanaOption {
        chains.removeAll { $0 == .solana }
    }
    popup.dataSource = chains
    popup.completionHandler = { selectedChain in
      AppState.shared.isSelectedAllChain = (selectedChain == .all)
      if allowAllChainOption && selectedChain == .all {
        AppDelegate.shared.coordinator.overviewTabCoordinator?.rootViewController.viewModel.currentChain = .all
        AppDelegate.shared.coordinator.loadBalanceCoordinator?.resume()
        AppEventManager.shared.postSelectAllChain()
      } else {
        AppState.shared.updateChain(chain: selectedChain)
      }
      onSelectChain(selectedChain)
    }
    UIApplication.shared.topMostViewController()?.present(popup, animated: true, completion: nil)
  }
  
  func openTransactionHistory() {
      guard let navigation = UIApplication.shared.topMostViewController() as? UINavigationController else { return }
      switch KNGeneralProvider.shared.currentChain {
      case .solana:
          let coordinator = KNTransactionHistoryCoordinator(navigationController: navigation, type: .solana)
          coordinator.delegate = self
          self.historyCoordinator = coordinator
          coordinate(coordinator: coordinator)
      default:
          if AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.historyV2) {
              let coordinator = HistoryV3Coordinator(navigationController: navigation)
              coordinate(coordinator: coordinator)
          } else {
              let coordinator = KNHistoryCoordinator(navigationController: navigation)
              coordinator.delegate = self
              self.historyCoordinator = coordinator
              coordinate(coordinator: coordinator)
          }
      }
  }
    
  func openExternalURL(url: String) {
    UIApplication.shared.topMostViewController()?.openSafari(with: url)
  }
  
  func openSupportURL() {
    UIApplication.shared.topMostViewController()?.openSafari(with: Constants.supportURL)
  }
  
  func openTxHash(txHash: String, chainID: Int) {
    guard let chain = ChainType.make(chainID: chainID) else { return }
    guard let url = URL(string: chain.customRPC().etherScanEndpoint + "tx/" + txHash) else { return }
    UIApplication.shared.topMostViewController()?.openSafari(with: url)
  }
  
  func openToken(navigationController: UINavigationController, address: String, chainID: Int) {
    guard let chain = ChainType.make(chainID: chainID) else { return }
    let currencyMode = CurrencyMode(rawValue: UserDefaults.standard.integer(forKey: Constants.currentCurrencyMode)) ?? .quote
    guard let vc = TokenModule.createTokenDetailViewController(address: address, chain: chain, currencyMode: currencyMode) else { return }
    vc.hidesBottomBarWhenPushed = false
    navigationController.pushViewController(vc, animated: true, completion: nil)
  }
  
  func openTokenTransfer(navigationController: UINavigationController, token: Token) {
      let tokenObject = KNSupportedTokenStorage.shared.supportedToken.first { $0.address == token.address }?.toObject() ?? token.toObject()
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: navigationController,
      balances: [:],
      from: tokenObject
    )
    coordinator.delegate = self
    coordinate(coordinator: coordinator)
  }
    
    func openSwap() {
        AppDelegate.shared.coordinator.tabbarController.selectedIndex = 1
        AppDelegate.shared.coordinator.tabbarController.navigationController?.popToRootViewController(animated: true)
        
    }
  
  func openSwap(token: Token) {
      AppDelegate.shared.coordinator.swapV2Coordinator?.appCoordinatorShouldOpenExchangeForToken(token, isReceived: false)
      AppDelegate.shared.coordinator.tabbarController.selectedIndex = 1
  }
    
    func openEarn() {
        AppDelegate.shared.coordinator.tabbarController.selectedIndex = 3
        AppDelegate.shared.coordinator.tabbarController.navigationController?.popToRootViewController(animated: false)
        AppDelegate.shared.coordinator.earnCoordinator?.openEarningOptions()
    }
    
    func openEarnPortfolio() {
        AppDelegate.shared.coordinator.tabbarController.selectedIndex = 3
        AppDelegate.shared.coordinator.tabbarController.navigationController?.popToRootViewController(animated: false)
        AppDelegate.shared.coordinator.earnCoordinator?.openPortfolio()
    }
    
    func openEarnReward() {
        AppDelegate.shared.coordinator.tabbarController.selectedIndex = 3
        AppDelegate.shared.coordinator.tabbarController.navigationController?.popToRootViewController(animated: false)
        AppDelegate.shared.coordinator.earnCoordinator?.openEarnReward()
    }

	func openSwap(from: Token, to: Token) {
        AppDelegate.shared.coordinator.swapV2Coordinator?.appCoordinatorOpenSwap(from: from, to: to)
        AppDelegate.shared.coordinator.tabbarController.selectedIndex = 1
    }
  
}

extension AppRouter: KNHistoryCoordinatorDelegate {
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    // No need to handle
  }
  
  func historyCoordinatorDidClose() {
    removeCoordinator(historyCoordinator!)
    historyCoordinator = nil
  }
  
}

extension AppRouter: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    
  }
  
  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
      removeCoordinator(coordinator)
  }
  
}

extension AppRouter {
    
    func getTopMostNavigation() -> UINavigationController? {
        let topViewController = UIApplication.shared.topMostViewController()
        if let nav = topViewController as? UINavigationController {
            return nav
        } else {
            return topViewController?.navigationController
        }
    }
    
}
