//
//  TokenSyncWorker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

class TokenSyncWorker: Worker {
    
    let chainID: Int
    let chainDB = ChainDB.shared
    
    init(chainID: Int) {
        self.chainID = chainID
        super.init(operations: [])
        if chainDB.isConfigEnabled(chainID: chainID, key: kTokenListApiSupported) {
            operations.append(ApiTokenSyncOperation(chainID: chainID))
        }
    }
    
}
