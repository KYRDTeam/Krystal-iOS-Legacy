//
//  GasPriceManager.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 01/11/2022.
//

import Foundation
import BaseWallet
import Services
import Dependencies
import BigInt
import Utilities

public class GasPriceManager {
    
    public static let shared = GasPriceManager()
    private let gasService = GasService()
    
    private init() {}
    
    var gasConfig: [ChainType: GasPriceResponse] = [:]
    
    public func scheduleFetchAllChainGasPrice() {
        fetchAllNetworkGasPrice()
        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.fetchAllNetworkGasPrice()
        }
    }
    
    func fetchAllNetworkGasPrice() {
        ChainType.allCases.forEach { chain in
            fetchGasPrice(chain: chain)
        }
    }
    
    func fetchGasPrice(chain: ChainType) {
        gasService.getGasPrice(chain: chain) { [weak self] gasResponse in
            if let gasResponse = gasResponse {
                self?.gasConfig[chain] = gasResponse
            }
        }
    }
    
}

extension GasPriceManager: GasConfig {
    public var defaultApproveGasLimit: BigInt {
        return BigInt(160_000)
    }
    
    public var defaultExchangeGasLimit: BigInt {
        return BigInt(650_000)
    }
    public var defaultTransferGasLimit: BigInt {
        return BigInt(180_000)
    }
  
    public var earnGasLimitDefault: BigInt {
        BigInt(1_140_000)
    }
    
    public func getLowGasPrice(chain: ChainType) -> BigInt {
        return gasConfig[chain]?.gasPrice.low.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
    }
    
    public func getStandardGasPrice(chain: ChainType) -> BigInt {
        return gasConfig[chain]?.gasPrice.standard.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
    }
    
    public func getFastGasPrice(chain: ChainType) -> BigInt {
        return gasConfig[chain]?.gasPrice.fast.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
    }
    
    public func getSuperFastGasPrice(chain: ChainType) -> BigInt {
        let fastGas = getFastGasPrice(chain: chain)
        if fastGas < BigInt(10) * TransactionConstants.oneGWei {
            return BigInt(20) * TransactionConstants.oneGWei
        }
        return fastGas * BigInt(2)
    }
    
    public func getLowPriorityFee(chain: ChainType) -> BigInt? {
        return gasConfig[chain]?.priorityFee?.low.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }
    
    public func getStandardPriorityFee(chain: ChainType) -> BigInt? {
        return gasConfig[chain]?.priorityFee?.standard.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }
    
    public func getFastPriorityFee(chain: ChainType) -> BigInt? {
        return gasConfig[chain]?.priorityFee?.fast.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }
    
    public func getSuperFastPriorityFee(chain: ChainType) -> BigInt? {
        if let fastPriority = getFastPriorityFee(chain: chain) {
            return fastPriority * BigInt(2)
        }
        return nil
    }
    
    public func getBaseFee(chain: ChainType) -> BigInt? {
        return gasConfig[chain]?.baseFee?.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }
    
}
