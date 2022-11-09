//
//  TxProcessorProtocol.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation

public protocol TxProcessorProtocol {
    func process(stakeTx: StakeTxObject)
}
