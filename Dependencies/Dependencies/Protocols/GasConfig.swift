//
//  GasConfig.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BigInt
import BaseWallet

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
}
