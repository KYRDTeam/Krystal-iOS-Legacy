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

    func sendTxToNode(data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void) {
        KNGeneralProvider.shared.sendSignedTransactionData(data, chain: chain, completion: completion)
    }
    
    func savePendingTx(txInfo: PendingTxInfo) {
        let internalTx = InternalHistoryTransaction(
            type: convertToInternalTxType(pendingTxType: txInfo.type),
            state: .pending,
            fromSymbol: txInfo.fromSymbol,
            toSymbol: txInfo.toSymbol,
            transactionDescription: txInfo.description,
            transactionDetailDescription: txInfo.detail,
            transactionObj: txInfo.legacyTx?.toSignTransactionObject(),
            eip1559Tx: txInfo.eip1559Tx,
            chain: txInfo.chain
        )
        internalTx.hash = txInfo.hash
        internalTx.nonce = txInfo.nonce
        internalTx.time = txInfo.date
        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalTx)
    }
    
    func convertToInternalTxType(pendingTxType: TxType) -> HistoryModelType {
        switch pendingTxType {
        case .earn:
            return .earn
        case .approval:
            return .allowance
        }
    }
    
}
