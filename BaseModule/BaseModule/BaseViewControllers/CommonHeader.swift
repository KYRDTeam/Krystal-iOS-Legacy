//
//  CommonHeader.swift
//  BaseModule
//
//  Created by Tung Nguyen on 20/02/2023.
//

import Foundation
import Utilities
import UIKit
import Dependencies
import AppState
import ChainModule

public class CommonHeader: BaseXibView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chainIconImageView: UIImageView!
    @IBOutlet weak var chainNameButton: UIButton!
    @IBOutlet weak var addWalletContainerView: UIView!
    @IBOutlet weak var walletInfoView: UIView!
    @IBOutlet weak var walletNameButton: UIButton!
    @IBOutlet weak var backupIcon: UIImageView!
    @IBOutlet weak var historyButton: UIButton!
    public var onBackTapped: (() -> ())?
    
    public var supportAllNetworks: Bool = false

    public override func commonInit() {
        super.commonInit()
        
        observeNotifications()
        reload()
        reloadWalletInfo()
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .appSwitchedChain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .appAllNetworksSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWalletInfo), name: .appWalletsListHasUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWalletInfo), name: .appAddressChanged, object: nil)
    }
    
    @objc func reloadWalletInfo() {
        let isGuestMode = AppState.shared.currentAddress.id.isEmpty
        addWalletContainerView.isHidden = !isGuestMode
        walletInfoView.isHidden = isGuestMode
        backupIcon.isHidden = AppState.shared.isWalletBackedUp(walletID: AppState.shared.currentAddress.walletID)
        walletNameButton.setTitle(AppState.shared.currentAddress.name, for: .normal)
    }
    
    @objc func reload() {
        if supportAllNetworks && AppState.shared.isSelectingAllNetworks {
            let chain = ChainDB.shared.getChain(byID: 0)
            chainIconImageView.loadImage(chain?.iconUrl)
            chainNameButton.setTitle(chain?.name, for: .normal)
        } else {
            let chain = AppState.shared.selectedChain!
            chainIconImageView.loadImage(chain.iconUrl)
            chainNameButton.setTitle(chain.name, for: .normal)
        }
    }
    
    @IBAction func onAddWalletTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func onChainTapped(_ sender: UIButton) {
        AppDependencies.router.openChainList(showAllNetworksOption: supportAllNetworks)
    }
    
    @IBAction func historyTapped(_ sender: UIButton) {
        AppDependencies.router.openTransactionHistory()
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        onBackTapped?()
    }
    
    @objc func openWalletList() {
        
    }
    
    
    
}
