//
//  GasConfig.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BigInt
import BaseWallet
import AppState

public protocol GasConfig {
    var defaultExchangeGasLimit: BigInt { get }
    var defaultTransferGasLimit: BigInt { get }
    var defaultApproveGasLimit: BigInt { get }
    var earnGasLimitDefault: BigInt { get }
    
    func getLowGasPrice(chain: ChainType) -> BigInt
    func getStandardGasPrice(chain: ChainType) -> BigInt
    func getFastGasPrice(chain: ChainType) -> BigInt
    func getSuperFastGasPrice(chain: ChainType) -> BigInt
    
    func getLowPriorityFee(chain: ChainType) -> BigInt?
    func getStandardPriorityFee(chain: ChainType) -> BigInt?
    func getFastPriorityFee(chain: ChainType) -> BigInt?
    func getSuperFastPriorityFee(chain: ChainType) -> BigInt?
    
    func getBaseFee(chain: ChainType) -> BigInt?
    func getFastEstTime(chain: ChainType) -> Int?
    func getStandardEstTime(chain: ChainType) -> Int?
    func getSlowEstTime(chain: ChainType) -> Int?
}

public extension GasConfig {
    
    var currentChainLowGasPrice: BigInt {
        return getLowGasPrice(chain: AppState.shared.currentChain)
    }
    
    var currentChainStandardGasPrice: BigInt {
        return getStandardGasPrice(chain: AppState.shared.currentChain)
    }
    
    var currentChainFastGasPrice: BigInt {
        return getFastGasPrice(chain: AppState.shared.currentChain)
    }
    
    var currentChainSuperFastGasPrice: BigInt {
        return getSuperFastGasPrice(chain: AppState.shared.currentChain)
    }
    
    var currentChainLowPriorityFee: BigInt? {
        return getLowPriorityFee(chain: AppState.shared.currentChain)
    }
    
    var currentChainStandardPriorityFee: BigInt? {
        return getStandardPriorityFee(chain: AppState.shared.currentChain)
    }
    
    var currentChainFastPriorityFee: BigInt? {
        return getFastPriorityFee(chain: AppState.shared.currentChain)
    }
    
    var currentChainSuperFastPriorityFee: BigInt? {
        return getSuperFastPriorityFee(chain: AppState.shared.currentChain)
    }
    
    var getCurrentChainBaseFee: BigInt? {
        return getBaseFee(chain: AppState.shared.currentChain)
    }
    
    var currentChainFastEstTime: Int? {
        return getFastEstTime(chain: AppState.shared.currentChain)
    }
    
    var currentChainStandardEstTime: Int? {
        return getStandardEstTime(chain: AppState.shared.currentChain)
    }
    
    var currentChainSlowEstTime: Int? {
        return getSlowEstTime(chain: AppState.shared.currentChain)
    }
}
