//
//  BridgeTrackingExtraData.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
import TransactionModule

class BridgeTrackingExtraData: TxTrackingExtraData {
    var srcChainId: String
    var srcToken: String
    var srcTokenAmount: String
    var destChainId: String
    var destToken: String
    var destTokenAmount: String
    var bridgeFee: String
    
    init(srcChainId: String, srcToken: String, srcTokenAmount: String, destChainId: String, destToken: String, destTokenAmount: String, bridgeFee: String) {
        self.srcChainId = srcChainId
        self.srcToken = srcToken
        self.srcTokenAmount = srcTokenAmount
        self.destChainId = destChainId
        self.destToken = destToken
        self.destTokenAmount = destTokenAmount
        self.bridgeFee = bridgeFee
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
}
