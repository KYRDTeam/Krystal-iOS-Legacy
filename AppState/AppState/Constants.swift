//
//  Constants.swift
//  AppState
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import BaseWallet

struct Constants {
    
    struct StorageKeys {
        static let currentChain = "current-chain-save-key.data"
        static let currentAddress = "current-address-save-key.data"
        static let isWalletBackedUp = "is-wallet-backed-up-"
    }
    
    struct UserDefaultKeys {
        static let kIsWalletBackedUp = "IS_BACKED_UP_"
        static let kLastUsedAddress = "LAST_USED_WALLET"
    }
    
    static let defaultChain: ChainType = .eth
    
}
