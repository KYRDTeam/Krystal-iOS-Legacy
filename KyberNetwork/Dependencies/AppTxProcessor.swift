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
    
    func hasPendingTx() -> Bool {
        return !EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty
    }
    
    func observePendingTxListChanged() {
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(pendingTxListUpdated),
          name: Notification.Name(kTransactionDidUpdateNotificationKey),
          object: nil
        )
    }
    
    @objc func pendingTxListUpdated() {
        TransactionManager.onPendingTxListUpdated()
    }

    func sendTxToNode(data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void) {
        KNGeneralProvider.shared.sendSignedTransactionData(data, chain: chain, completion: completion)
    }
    
    func savePendingTx(txInfo: PendingTxInfo) {
        let internalTx = InternalHistoryTransaction(
            type: convertToInternalTxType(pendingTxType: txInfo.type),
            state: .pending,
            fromSymbol: txInfo.sourceSymbol,
            toSymbol: txInfo.destSymbol,
            transactionDescription: txInfo.description,
            transactionDetailDescription: txInfo.detail,
            transactionObj: txInfo.legacyTx?.toSignTransactionObject(),
            eip1559Tx: txInfo.eip1559Tx,
            chain: txInfo.chain
        )
        internalTx.hash = txInfo.hash
        if let eip1559Nonce = txInfo.eip1559Tx?.nonce, let nonceInt = Int(eip1559Nonce) {
            internalTx.nonce = nonceInt
        } else {
            internalTx.nonce = txInfo.legacyTx?.nonce ?? 0
        }
        internalTx.time = txInfo.date
        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalTx)
    }
    
    func convertToInternalTxType(pendingTxType: TxType) -> HistoryModelType {
        switch pendingTxType {
        case .earn:
            return .earn
        case .approval:
            return .allowance
        case .claimStakingReward:
            return .contractInteraction
        case .unstake:
            return .withdraw
        }
    }
    
}
