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
    }
    
    struct UserDefaultKeys {
        static let kIsWalletBackedUp = "IS_BACKED_UP_"
    }
    
    static let defaultChain: ChainType = .eth
    
}
