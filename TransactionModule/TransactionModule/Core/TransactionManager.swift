//
//  TransactionManager.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 10/11/2022.
//

import Foundation
import Dependencies

public extension Notification.Name {
    static let kTxStatusUpdated = Notification.Name("kTxStatusUpdated")
    static let kPendingTxListUpdated = Notification.Name("kPendingTxListUpdated")
}

public class TransactionManager {
    
    public static var txProcessor: TxProcessorProtocol! {
        didSet {
            txProcessor.observePendingTxListChanged()
        }
    }
    
    public static func onTransactionStatusUpdated(hash: String, status: InternalTransactionState) {
        NotificationCenter.default.post(name: .kTxStatusUpdated, object: nil, userInfo: [
            "status": status,
            "hash": hash
        ])
    }
    
    public static func onPendingTxListUpdated() {
        NotificationCenter.default.post(name: .kPendingTxListUpdated, object: nil, userInfo: nil)
    }
    
}
