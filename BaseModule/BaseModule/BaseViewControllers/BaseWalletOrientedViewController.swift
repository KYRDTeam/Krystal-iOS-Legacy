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
        chainIcon?.image = AppState.shared.currentChain.squareIcon()
        chainButton?.setTitle(AppState.shared.currentChain.chainName(), for: .normal)
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
        AppDependencies.router.openWalletList()
    }
    
    open func openSwitchChain() {
        AppDependencies.router.openChainList()
    }
    
}

extension ChainType {
    
    func squareIcon() -> UIImage {
        switch self {
        case .all:
            return .allNetworkSquare
        case .eth:
            return .chainEthSquare
        case .ropsten:
            return .chainEthSquare
        case .bsc:
            return .chainBscSquare
        case .bscTestnet:
            return .chainBscSquare
        case .polygon:
            return .chainPolygonSquare
        case .polygonTestnet:
            return .chainPolygonSquare
        case .avalanche:
            return .chainAvaxSquare
        case .avalancheTestnet:
            return .chainAvaxSquare
        case .cronos:
            return .chainCronosSquare
        case .fantom:
            return .chainFantomSquare
        case .arbitrum:
            return .chainArbitrumSquare
        case .aurora:
            return .chainAuroraSquare
        case .solana:
            return .chainSolanaSquare
        case .klaytn:
            return .chainKlaytnSquare
        }
    }
    
}
