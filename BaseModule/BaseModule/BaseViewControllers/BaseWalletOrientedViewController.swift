//
//  BaseWalletOrientedViewController.swift
//  BaseModule
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit
import BaseWallet
import AppState
import KrystalWallets
import Dependencies

open class BaseWalletOrientedViewController: KNBaseViewController {
    @IBOutlet weak var walletButton: UIButton?
    @IBOutlet weak var backupIcon: UIImageView?
    @IBOutlet weak var chainIcon: UIImageView?
    @IBOutlet weak var chainButton: UIButton?
    @IBOutlet weak var walletView: UIView?
    
    var currentAddress: KAddress {
        return AppState.shared.currentAddress
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupGestures()
        observeNotifications()
        reloadWallet()
        reloadChain()
    }
    
    func setupGestures() {
        walletView?.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onWalletButtonTapped))
        gesture.cancelsTouchesInView = false
        walletView?.addGestureRecognizer(gesture)
    }
    
    deinit {
        unobserveNotifications()
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppSwitchChain),
            name: .appChainChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppSwitchAddress),
            name: .appAddressChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWalletListUpdated),
            name: .appWalletsListHasUpdate,
            object: nil
        )
    }
    
    func unobserveNotifications() {
        NotificationCenter.default.removeObserver(self, name: .appAddressChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appAddressChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appWalletsListHasUpdate, object: nil)
    }
    
    open func reloadWallet() {
        walletButton?.setTitle(currentAddress.name, for: .normal)
        backupIcon?.isHidden = currentAddress.walletID.isEmpty || AppState.shared.isWalletBackedUp(walletID: currentAddress.walletID)
    }
    
    open func reloadChain() {
        //    chainIcon?.image = KNGeneralProvider.shared.currentChain.squareIcon()
        //    chainButton?.setTitle(KNGeneralProvider.shared.currentChain.chainName(), for: .normal)
    }
    
    @objc open func onWalletListUpdated() {
        reloadWallet()
    }
    
    @objc open func onWalletButtonTapped() {
        
    }
    
    @IBAction func onChainButtonTapped(_ sender: Any) {
        
    }
    
    @objc open func onAppSwitchChain() {
        reloadChain()
    }
    
    @objc open func onAppSwitchAddress() {
        reloadWallet()
    }
    
    open func openWalletList() {
        Dependencies.router.openWalletList()
    }
    
    open func openSwitchChain() {
        Dependencies.router.openChainList()
    }
    
}
