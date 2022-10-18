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
  @IBOutlet weak var browsingView: UIView?
  override func viewDidLoad() {
    super.viewDidLoad()
    observeNotifications()
    updateChainInfo()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    browsingView?.isHidden = !KNGeneralProvider.shared.isBrowsingMode
  }
  
  deinit {
    unobserveNotifications()
  }
  
  override func observeNotifications() {
    super.observeNotifications()
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
    super.unobserveNotifications()
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
  
  func updateChainInfo() {
    chainIcon?.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainLabel?.text = KNGeneralProvider.shared.currentChain.chainName()
  }

  func reloadChainUI() {
    updateChainInfo()
  }
  
  func reloadChainData() {
    
  }
  
  @IBAction func onAddWalletButtonTapped(_ sender: Any) {
    guard let parent = navigationController?.tabBarController else { return }
    let coordinator = KNAddNewWalletCoordinator(parentViewController: parent)
    coordinator.start(type: .full)
    addCoordinator(coordinator)
    
    if self.isKind(of: OverviewBrowsingViewController.self) {
      MixPanelManager.track("home_connect_wallet", properties: ["screenid": "homepage"])
    } else if self.isKind(of: SwapV2ViewController.self) {
      MixPanelManager.track("swap_connect_wallet", properties: ["screenid": "swap"])
    } else if self.isKind(of: KSendTokenViewController.self) {
      MixPanelManager.track("transfer_connect_wallet", properties: ["screenid": "transfer"])
    } else if self.isKind(of: EarnViewController.self) {
      MixPanelManager.track("earn_connect_wallet", properties: ["screenid": "earn"])
    } else if self.isKind(of: InvestViewController.self) {
      MixPanelManager.track("explore_connect_wallet", properties: ["screenid": "explore"])
    } else if self.isKind(of: KNSettingsTabViewController.self) {
      MixPanelManager.track("settings_connect_wallet", properties: ["screenid": "settings"])
    } else if self.isKind(of: BridgeViewController.self) {
      MixPanelManager.track("bridge_connect_wallet", properties: ["screenid": "bridge"])
    } else if self.isKind(of: EarnMenuViewController.self) {
      MixPanelManager.track("earn_pre_connect_wallet", properties: ["screenid": "earn_explore"])
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
    didSelectWallet(wallet: wallet, isCreatedFromBrowsing: true)
    AppDelegate.shared.coordinator.overviewTabCoordinator?.stop()
    AppDelegate.shared.coordinator.overviewTabCoordinator?.rootViewController.viewModel.currentChain = chain
    AppDelegate.shared.coordinator.overviewTabCoordinator?.start()
    browsingView?.isHidden = !KNGeneralProvider.shared.isBrowsingMode
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
}
