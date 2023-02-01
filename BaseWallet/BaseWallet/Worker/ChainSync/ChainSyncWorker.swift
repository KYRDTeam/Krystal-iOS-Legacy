//
//  ChainSyncWorker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

class ChainSyncWorker: Worker {
    var operations: [Operation] = []
    var queue: OperationQueue = OperationQueue()
    
    init(operations: [ChainSyncOperation]) {
        self.operations = operations
    }
}
