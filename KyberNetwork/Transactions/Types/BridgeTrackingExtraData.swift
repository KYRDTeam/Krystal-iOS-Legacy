//
//  BridgeTrackingExtraData.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
import TransactionModule

class BridgeTrackingExtraData: TxTrackingExtraData {
    let srcChainId: String
    let srcToken: String
    let srcTokenAmount: String
    let destChainId: String
    let destToken: String
    let destTokenAmount: String
    let bridgeFee: String
    let router: String
    
    enum CodingKeys: String, CodingKey {
        case srcChainId, srcToken, srcTokenAmount, destChainId, destToken, destTokenAmount, bridgeFee, router
    }
    
    init(srcChainId: String, srcToken: String, srcTokenAmount: String, destChainId: String, destToken: String, destTokenAmount: String, bridgeFee: String, router: String) {
        self.srcChainId = srcChainId
        self.srcToken = srcToken
        self.srcTokenAmount = srcTokenAmount
        self.destChainId = destChainId
        self.destToken = destToken
        self.destTokenAmount = destTokenAmount
        self.bridgeFee = bridgeFee
        self.router = router
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(srcChainId, forKey: .srcChainId)
        try container.encode(srcToken, forKey: .srcToken)
        try container.encode(srcTokenAmount, forKey: .srcTokenAmount)
        try container.encode(destChainId, forKey: .destChainId)
        try container.encode(destToken, forKey: .destToken)
        try container.encode(destTokenAmount, forKey: .destTokenAmount)
        try container.encode(bridgeFee, forKey: .bridgeFee)
        try container.encode(router, forKey: .router)
    }
}
