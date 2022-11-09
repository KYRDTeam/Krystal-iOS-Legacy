//
//  AppTxProcessor.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import TransactionModule
import AppState
import Dependencies
import Result

class AppTxProcessor: TxProcessorProtocol {
    
    var currentAddress: String {
        return AppState.shared.currentAddress.addressString
    }
    
    var currentChain: ChainType {
        return AppState.shared.currentChain
    }
    
    var currentNonce: Int {
        return AppDependencies.nonceStorage.currentNonce(chain: currentChain, address: currentAddress)
    }

    func sendTxToNode(data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void) {
        KNGeneralProvider.shared.sendSignedTransactionData(data, chain: chain, completion: completion)
    }
    
}
