//
//  AppRouter.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import SwapModule
import Dependencies
import UIKit
import KrystalWallets
import AppState

class AppRouter: AppRouterProtocol, Coordinator {
  
  var coordinators: [Coordinator] = []
  
  func start() {
    fatalError("Do not use this function")
  }
  
  func openAddWallet() {
    guard let parent = UIApplication.shared.topMostViewController() else { return }
    let coordinator = KNAddNewWalletCoordinator(parentViewController: parent)
    coordinator.start(type: .full)
    coordinate(coordinator: coordinator)
  }
  
  func openWalletList(currentChain: ChainType, allowAllChainOption: Bool,
                      onSelectWallet: @escaping (KWallet) -> (),
                      onSelectWatchAddress: @escaping (KAddress) -> Void) {
    let walletsList = WalletListV2ViewController()
    walletsList.allowAllChainOption = allowAllChainOption
    walletsList.onSelectWallet = onSelectWallet
    walletsList.onSelectWatchAddress = onSelectWatchAddress
    let navigation = UINavigationController(rootViewController: walletsList)
    navigation.setNavigationBarHidden(true, animated: false)
    UIApplication.shared.topMostViewController()?.present(navigation, animated: true, completion: nil)
  }
  
  func openChainList(allowAllChainOption: Bool, onSelectChain: @escaping (ChainType) -> Void) {
    MixPanelManager.track("import_select_chain_open", properties: ["screenid": "import_select_chain"])
    let popup = SwitchChainViewController(selected: AppState.shared.currentChain)
    var chains = WalletManager.shared.getAllAddresses(walletID: AppState.shared.currentAddress.walletID).flatMap { address in
      return ChainType.getAllChain().filter { chain in
        return chain != .all && chain.addressType == address.addressType
      }
    }
    if allowAllChainOption {
      chains = [.all] + chains
    }
    popup.dataSource = chains
    popup.completionHandler = { selectedChain in
      if allowAllChainOption && selectedChain == .all {
        AppDelegate.shared.coordinator.loadBalanceCoordinator?.shouldFetchAllChain = (selectedChain == .all)
        AppDelegate.shared.coordinator.loadBalanceCoordinator?.resume()
      } else {
        KNGeneralProvider.shared.currentChain = selectedChain
        AppEventCenter.shared.switchChain(chain: selectedChain)
        AppState.shared.updateChain(chain: selectedChain)
      }
      onSelectChain(selectedChain)
    }
    UIApplication.shared.topMostViewController()?.present(popup, animated: true, completion: nil)
  }
  
  func createSwapViewController() -> UIViewController {
    return SwapModule.createSwapViewController()
  }
}
