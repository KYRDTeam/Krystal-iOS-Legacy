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
import Dependencies

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
        chainIcon?.image = AppState.shared.currentChain.squareIcon()
        chainLabel?.text = AppState.shared.currentChain.chainName()
        browsingView?.isHidden = !AppState.shared.isBrowsingMode
    }
    
    open func reloadChainUI() {
        updateChainInfo()
    }
    
    open func reloadChainData() {
        
    }
  
    open func handleAddWalletTapped() {
        AppDependencies.router.openAddWallet()
    }
  
  override open func handleChainButtonTapped() {
    AppDependencies.router.openChainList(currentChain, allowAllChainOption: supportAllChainOption, showSolanaOption: supportSolana) { [weak self] chain in
      self?.onChainSelected(chain: chain)
    }
  }
    
    @IBAction open func onAddWalletButtonTapped(_ sender: Any) {
      handleAddWalletTapped()
    }
    
    @IBAction func onSwitchChainButtonTapped(_ sender: Any) {
      AppDependencies.router.openChainList(currentChain, allowAllChainOption: supportAllChainOption, showSolanaOption: supportSolana) { [weak self] chain in
        self?.onChainSelected(chain: chain)
      }
    }
}
