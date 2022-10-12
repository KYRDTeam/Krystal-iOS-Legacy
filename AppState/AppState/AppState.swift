//
//  AppState.swift
//  AppState
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import BaseWallet
import Utilities
import KrystalWallets

public class AppState {
    
    public static let shared = AppState()
    
    public private(set) var currentChain: ChainType = Storage.retrieve(Constants.StorageKeys.currentChain, as: ChainType.self) ?? Constants.defaultChain {
        didSet {
            Storage.store(self.currentChain, as: Constants.StorageKeys.currentChain)
        }
    }
    
    @AppStateUserDefault(key: "LAST_USED_WALLET", defaultValue: WalletManager.shared.createEmptyAddress())
    public private(set) var currentAddress: KAddress
    
    public func isWalletBackedUp(walletID: String) -> Bool {
        if let wallet = WalletManager.shared.getWallet(id: walletID), wallet.importType != .mnemonic {
            return true
        }
        return UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.kIsWalletBackedUp + walletID)
    }
    
    public func markWalletBackedUp(walletID: String) {
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultKeys.kIsWalletBackedUp + walletID)
    }
    
    public func unmarkWalletBackedUp(walletID: String) {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultKeys.kIsWalletBackedUp + walletID)
    }
    
    
}
