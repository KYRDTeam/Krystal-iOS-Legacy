//
//  InAppBrowsingViewController.swift
//  BaseModule
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation
import UIKit
import KrystalWallets
import BaseWallet
import AppState

open class InAppBrowsingViewController: BaseWalletOrientedViewController {
    @IBOutlet open weak var chainLabel: UILabel?
    @IBOutlet open weak var browsingView: UIView?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        observeNotifications()
        updateChainInfo()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        browsingView?.isHidden = !AppState.shared.isBrowsingMode
    }
    
    deinit {
        unobserveNotifications()
    }
    
  open override func observeNotifications() {
        super.observeNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppBrowsingSwitchChain),
            name: .appChainChanged,
            object: nil
        )
        //    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
        //    NotificationCenter.default.addObserver(
        //      self,
        //      selector: #selector(self.tokenObjectListDidUpdate(_:)),
        //      name: supportedTokensName,
        //      object: nil
        //    )
    }
    
  open override func unobserveNotifications() {
        super.unobserveNotifications()
        NotificationCenter.default.removeObserver(self, name: .appChainChanged, object: nil)
        
//        let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
//        NotificationCenter.default.removeObserver(
//            self,
//            name: supportedTokensName,
//            object: nil
//        )
    }
    
    @objc open func onAppBrowsingSwitchChain() {
        reloadChainUI()
    }
    
    @objc open func tokenObjectListDidUpdate(_ sender: Any?) {
        reloadChainData()
    }
    
    open func updateChainInfo() {
//        chainIcon?.image = KNGeneralProvider.shared.currentChain.squareIcon()
//        chainLabel?.text = KNGeneralProvider.shared.currentChain.chainName()
    }
    
    open func reloadChainUI() {
        updateChainInfo()
    }
    
    open func reloadChainData() {
        
    }
    
    @IBAction open func onAddWalletButtonTapped(_ sender: Any) {
        //    present(addWalletCoordinator.navigationController, animated: false) {
        //      self.addWalletCoordinator.start(type: .full)
        //    }
        //
        //    if self.isKind(of: OverviewBrowsingViewController.self) {
        //      MixPanelManager.track("home_connect_wallet", properties: ["screenid": "homepage"])
        //    } else if self.isKind(of: SwapV2ViewController.self) {
        //      MixPanelManager.track("swap_connect_wallet", properties: ["screenid": "swap"])
        //    } else if self.isKind(of: KSendTokenViewController.self) {
        //      MixPanelManager.track("transfer_connect_wallet", properties: ["screenid": "transfer"])
        //    } else if self.isKind(of: EarnViewController.self) {
        //      MixPanelManager.track("earn_connect_wallet", properties: ["screenid": "earn"])
        //    } else if self.isKind(of: InvestViewController.self) {
        //      MixPanelManager.track("explore_connect_wallet", properties: ["screenid": "explore"])
        //    } else if self.isKind(of: KNSettingsTabViewController.self) {
        //      MixPanelManager.track("settings_connect_wallet", properties: ["screenid": "settings"])
        //    } else if self.isKind(of: BridgeViewController.self) {
        //      MixPanelManager.track("bridge_connect_wallet", properties: ["screenid": "bridge"])
        //    } else if self.isKind(of: EarnMenuViewController.self) {
        //      MixPanelManager.track("earn_pre_connect_wallet", properties: ["screenid": "earn_explore"])
        //    }
    }
    
    @IBAction func onSwitchChainButtonTapped(_ sender: Any) {
        openBrowsingSwitchChain()
    }
    
    open func openBrowsingSwitchChain() {
        //    let popup = SwitchChainViewController(selected: currentChain)
        //    popup.dataSource = ChainType.getAllChain()
        //    popup.completionHandler = { [weak self] selectedChain in
        //      self?.onChainSelected(chain: selectedChain)
        //    }
        //    present(popup, animated: true, completion: nil)
    }
    
    open func addNewWallet(wallet: KWallet, chain: ChainType) {
//            AppDelegate.shared.setupMixPanel()
//            onChainSelected(chain: chain)
//            didSelectWallet(wallet: wallet, isCreatedFromBrowsing: true)
//            AppDelegate.shared.coordinator.overviewTabCoordinator?.stop()
//            AppDelegate.shared.coordinator.overviewTabCoordinator?.rootViewController.viewModel.currentChain = chain
//            AppDelegate.shared.coordinator.overviewTabCoordinator?.start()
//            browsingView?.isHidden = !KNGeneralProvider.shared.isBrowsingMode
//            if AppDelegate.shared.coordinator.tabbarController != nil {
//              AppDelegate.shared.coordinator.tabbarController.tabBar.isHidden = false
//            }
    }
    
    open func addNewWallet(watchAddress: KAddress, chain: ChainType) {
//        onChainSelected(chain: chain)
//        didSelectWatchWallet(address: watchAddress)
    }
    
    open func addNewWalletDidSendRefCode(_ code: String) {
//        KrystalService().sendRefCode(address: currentAddress, code.uppercased()) { _, message in
//            AppDelegate.shared.coordinator.tabbarController.showTopBannerView(message: message)
//        }
    }
    
    open func removeWallet(wallet: KWallet) {

    }
}
