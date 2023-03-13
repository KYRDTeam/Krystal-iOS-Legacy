//
//  TransferViewModelProtocol.swift
//  Transfer
//
//  Created by Tung Nguyen on 06/03/2023.
//

import Foundation
import BigInt
import TransactionModule

protocol TransferViewModelProtocol {
    var gasLimit: BigInt { get }
    var gasPrice: BigInt { get }
    var l1Fee: BigInt { get }
    var minimumRentExemption: BigInt { get }
    var settingObject: TxSettingObject { get set }
    
    func resolveDomain(_ domain: String, completion: @escaping (String?) -> ())
}
