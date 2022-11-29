//
//  TxSender.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/11/2022.
//

import Foundation
import BaseWallet
import Result

public protocol TxNodeSenderProtocol {
    func sendTx(data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void)
}
