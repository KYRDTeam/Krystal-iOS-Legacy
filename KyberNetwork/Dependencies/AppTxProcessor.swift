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
    
    var txSender: TxNodeSenderProtocol = TxNodeSender()
    
    func isTokenApproving(address: String) -> Bool {
        let allTransactions = EtherscanTransactionStorage.shared.getInternalHistoryTransaction()
        let pendingApproveTxs = allTransactions.filter { tx in
            return tx.transactionDetailDescription.lowercased() == address.lowercased() && tx.type == .allowance
        }
        return !pendingApproveTxs.isEmpty
    }
    
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
    
    func savePendingTx(txInfo: PendingTxInfo, extraInfo: [String: String]?) {
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
        internalTx.extraUserInfo = extraInfo
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
        case .swap:
            return .swap
        }
    }
    
}
