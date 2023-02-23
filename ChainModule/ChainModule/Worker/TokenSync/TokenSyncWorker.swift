//
//  TokenSyncWorker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

public class TokenSyncWorker: Worker {
    
    let chainID: Int
    
    public init(chainID: Int) {
        self.chainID = chainID
        super.init(operations: [])
        if ChainDB.shared.isConfigEnabled(chainID: chainID, key: kTokenListApiSupported) {
            operations.append(ApiTokenSyncOperation(chainID: chainID))
        }
    }
    
}
