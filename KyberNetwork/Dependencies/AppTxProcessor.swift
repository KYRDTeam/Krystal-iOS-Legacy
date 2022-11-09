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
    
    func process(stakeTx: StakeTxObject) {
        if AppState.shared.currentChain.isSupportedEIP1559() {
            // process 1559 tx
            
        } else {
//            let tx = stakeTx.txObject.convertToSignTransaction(address: currentAddress, nonce: currentNonce, settings: <#T##UserSettings#>)
        }
    }

    func getEstimatedGasLimit(tx: SignTransaction) {
//        KNGeneralProvider.shared.getEstimateGasLimit(transaction: <#T##SignTransaction#>, completion: <#T##(Result<BigInt, AnyError>) -> Void#>)
    }
    
}
