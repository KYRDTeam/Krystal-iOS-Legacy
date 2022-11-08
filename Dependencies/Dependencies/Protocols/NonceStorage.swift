//
//  NonceTracker.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BaseWallet

public protocol NonceStorage {
    func currentNonce(chain: ChainType, address: String) -> Int
    func updateNonce(chain: ChainType, address: String, value: Int)
    func increaseNonce(chain: ChainType, address: String, value: Int)
}
