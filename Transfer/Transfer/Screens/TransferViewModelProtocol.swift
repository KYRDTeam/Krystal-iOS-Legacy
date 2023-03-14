//
//  TransferViewModelProtocol.swift
//  Transfer
//
//  Created by Tung Nguyen on 06/03/2023.
//

import Foundation
import BigInt
import TransactionModule
import ChainModule

protocol TransferViewModelProtocol {
    var token: Token { get }
    var balance: BigInt { get }
    var estimatedGasFee: BigInt { get }
    var maxFee: BigInt { get }
    
    func resolveDomain(_ domain: String, completion: @escaping (String?) -> ())
    func checkEligible(_ address: String, completion: @escaping (Bool) -> ())
}
