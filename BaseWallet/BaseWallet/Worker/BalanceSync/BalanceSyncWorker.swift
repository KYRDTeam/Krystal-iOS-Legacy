//
//  BalanceSyncWorker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

class BalanceSyncWorker: Worker {
    public var operations: [Operation] = []
    public var queue: OperationQueue = OperationQueue()
    
    public init(operations: [ChainSyncOperation]) {
        self.operations = operations
    }    
}
