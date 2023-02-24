//
//  Chain+AddressType.swift
//  ChainModule
//
//  Created by Tung Nguyen on 20/02/2023.
//

import Foundation
import KrystalWallets

public extension Chain {
    
    var addressType: KAddressType {
        switch type {
        case "SOL":
            return .solana
        default:
            return .evm
        }
    }
    
}
