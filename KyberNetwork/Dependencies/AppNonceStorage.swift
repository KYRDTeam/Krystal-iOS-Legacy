//
//  AppNonceStorage.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 31/10/2022.
//

import Foundation
import Dependencies

class AppNonceStorage: NonceStorage {
    
    func currentNonce(chain: ChainType, address: String) -> Int {
        return NonceCache.shared.getCachingNonce(address: address, chain: chain)
    }
    
    func increaseNonce(chain: ChainType, address: String, value: Int) {
        NonceCache.shared.increaseNonce(address: address, chain: chain, increment: value)
    }
    
    func updateNonce(chain: ChainType, address: String, value: Int) {
        NonceCache.shared.updateNonce(address: address, chain: chain, nonce: value)
    }
    
}
