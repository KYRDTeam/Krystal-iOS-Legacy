//
//  BaseViewModel.swift
//  BaseModule
//
//  Created by Tung Nguyen on 11/11/2022.
//

import Foundation
import BaseWallet
import AppState
import KrystalWallets

open class BaseViewModel {
    
    public init() {}
    
    open var currentChain: ChainType {
        return AppState.shared.currentChain
    }
    
    open var currentAddress: KAddress {
        return AppState.shared.currentAddress
    }
    
}
