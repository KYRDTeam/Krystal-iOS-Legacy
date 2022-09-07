//
//  InAppBrowsingViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 06/09/2022.
//

import UIKit
import KrystalWallets

class InAppBrowsingViewController: BaseWalletOrientedViewController {
  @IBOutlet weak var chainLabel: UILabel?

  override func viewDidLoad() {
    super.viewDidLoad()
    observeNotifications()
  }
  
  deinit {
    unobserveNotifications()
  }
  
  override func observeNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onAppBrowsingSwitchChain),
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
  
  override func unobserveNotifications() {
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidSwitchChain, object: nil)
    
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: supportedTokensName,
      object: nil
    )
  }
  
  @objc func onAppBrowsingSwitchChain() {
    reloadChainUI()
  }
  
  @objc func tokenObjectListDidUpdate(_ sender: Any?) {
    reloadChainData()
  }

  func reloadChainUI() {
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
    openBrowsingSwitchChain()
  }
  
  func openBrowsingSwitchChain() {
    let popup = SwitchChainViewController(selected: currentChain)
    popup.dataSource = ChainType.getAllChain()
    popup.completionHandler = { [weak self] selectedChain in
      self?.onChainSelected(chain: selectedChain)
    }
    present(popup, animated: true, completion: nil)
  }
  
  override func addNewWallet(wallet: KWallet, chain: ChainType) {
    AppDelegate.shared.setupMixPanel()
    onChainSelected(chain: chain)
    didSelectWallet(wallet: wallet)
    AppDelegate.shared.coordinator.tabbarController.selectedIndex = 0
    AppDelegate.shared.coordinator.overviewTabCoordinator?.stop()
    AppDelegate.shared.coordinator.overviewTabCoordinator?.start()
  }
  
  override func addNewWallet(watchAddress: KAddress, chain: ChainType) {
    onChainSelected(chain: chain)
    didSelectWatchWallet(address: watchAddress)
  }
  
  override func addNewWalletDidSendRefCode(_ code: String) {
    KrystalService().sendRefCode(address: currentAddress, code.uppercased()) { _, message in
      AppDelegate.shared.coordinator.tabbarController.showTopBannerView(message: message)
    }
  }

  override func removeWallet(wallet: KWallet) {

  }
}
