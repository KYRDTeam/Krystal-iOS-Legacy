//
//  InAppBrowsingViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 06/09/2022.
//

import UIKit
import KrystalWallets

class InAppBrowsingViewController: KNBaseViewController {
  @IBOutlet weak var chainLabel: UILabel?
  @IBOutlet weak var chainIcon: UIImageView?
  
  var currentChain: ChainType {
    return KNGeneralProvider.shared.currentChain
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  lazy var addWalletCoordinator: KNAddNewWalletCoordinator = {
    let coordinator = KNAddNewWalletCoordinator()
    coordinator.delegate = self
    return coordinator
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    observeNotifications()
  }
  
  deinit {
    unobserveNotifications()
  }
  
  func observeNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onAppSwitchChain),
      name: AppEventCenter.shared.kAppDidSwitchChain,
      object: nil
    )
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: supportedTokensName,
      object: nil
    )
  }
  
  func unobserveNotifications() {
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidSwitchChain, object: nil)
    
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: supportedTokensName,
      object: nil
    )
  }
  
  @objc func onAppSwitchChain() {
    reloadChain()
  }
  
  @objc func tokenObjectListDidUpdate(_ sender: Any?) {
    reloadChainData()
  }

  func reloadChain() {
    chainIcon?.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainLabel?.text = KNGeneralProvider.shared.currentChain.chainName()
  }
  
  func reloadChainData() {
    
  }
  
  @IBAction func onAddWalletButtonTapped(_ sender: Any) {
//    let popup = AddWalletViewController()
////    popup.delegate = self
//    if AppDelegate.shared.coordinator.tabbarController != nil {
//      AppDelegate.shared.coordinator.tabbarController.tabBar.isHidden = true
//    }
//    self.navigationController?.pushViewController(popup, animated: true)
    present(addWalletCoordinator.navigationController, animated: false) {
      self.addWalletCoordinator.start(type: .full)
    }
  }
  
  @IBAction func onSwitchChainButtonTapped(_ sender: Any) {
    openSwitchChain()
  }
  
  func openSwitchChain() {
    let popup = SwitchChainViewController(selected: currentChain)
    popup.dataSource = ChainType.getAllChain()
    popup.completionHandler = { [weak self] selectedChain in
      self?.onChainSelected(chain: selectedChain)
    }
    present(popup, animated: true, completion: nil)
  }
  
  func onChainSelected(chain: ChainType) {
    KNGeneralProvider.shared.currentChain = chain
    AppEventCenter.shared.switchChain(chain: chain)
    AppDelegate.shared.coordinator.loadBalanceCoordinator?.shouldFetchAllChain = (chain == .all)
    AppDelegate.shared.coordinator.loadBalanceCoordinator?.resume()
  }
  
  func didSelectWallet(wallet: KWallet) {
    let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
    guard addresses.isNotEmpty else { return }
    if let matchingChainAddress = addresses.first(where: { $0.addressType == currentChain.addressType }) {
      AppDelegate.shared.coordinator.switchAddress(address: matchingChainAddress)
    } else {
      let address = addresses.first!
      guard let chain = ChainType.allCases.first(where: {
        return ($0 != .all) && $0.addressType == address.addressType
      }) else { return }
      self.onChainSelected(chain: chain)
      AppDelegate.shared.coordinator.switchAddress(address: address)
    }
  }
  
  func didSelectWatchWallet(address: KAddress) {
    if address.addressType == currentChain.addressType {
      if currentChain == .all {
        AppDelegate.shared.coordinator.switchToWatchAddress(address: address, chain: KNGeneralProvider.shared.currentChain)
        onChainSelected(chain: .all)
      } else {
        AppDelegate.shared.coordinator.switchToWatchAddress(address: address, chain: currentChain)
      }
    } else {
      guard let chain = ChainType.allCases.first(where: { $0 != .all && $0.addressType == address.addressType }) else { return }
      AppDelegate.shared.coordinator.switchToWatchAddress(address: address, chain: chain)
    }
  }
}

extension InAppBrowsingViewController: KNAddNewWalletCoordinatorDelegate {
  
  func addNewWalletCoordinator(didAdd wallet: KWallet, chain: ChainType) {
    AppDelegate.shared.setupMixPanel()
    onChainSelected(chain: chain)
    didSelectWallet(wallet: wallet)
    AppDelegate.shared.coordinator.tabbarController.selectedIndex = 0
    AppDelegate.shared.coordinator.overviewTabCoordinator?.stop()
    AppDelegate.shared.coordinator.overviewTabCoordinator?.start()
  }
  
  func addNewWalletCoordinator(didAdd watchAddress: KAddress, chain: ChainType) {
    onChainSelected(chain: chain)
    didSelectWatchWallet(address: watchAddress)
  }
  
  func addNewWalletCoordinatorDidSendRefCode(_ code: String) {
    KrystalService().sendRefCode(address: currentAddress, code.uppercased()) { _, message in
      AppDelegate.shared.coordinator.tabbarController.showTopBannerView(message: message)
    }
  }

  func addNewWalletCoordinator(remove wallet: KWallet) {

  }
}
