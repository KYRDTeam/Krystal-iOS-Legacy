//
//  SwapTrackingExtraData.swift
//  SwapModule
//
//  Created by Tung Nguyen on 27/02/2023.
//

import Foundation
import TransactionModule

class SwapTrackingExtraData: TxTrackingExtraData {
    var srcToken: String
    var srcTokenAmount: Double
    var srcTokenAmountUsd: Double
    var destToken: String
    var destTokenAmount: Double
    var destTokenAmountUsd: Double
    var networkFee: Double
    var platform: String
    
    enum CodingKeys: String, CodingKey {
        case srcToken, srcTokenAmount, srcTokenAmountUsd, destToken, destTokenAmount, destTokenAmountUsd, networkFee, platform
    }
    
    init(srcToken: String, srcTokenAmount: Double, srcTokenAmountUsd: Double, destToken: String, destTokenAmount: Double, destTokenAmountUsd: Double, networkFee: Double, platform: String) {
        self.srcToken = srcToken
        self.srcTokenAmount = srcTokenAmount
        self.srcTokenAmountUsd = srcTokenAmountUsd
        self.destToken = destToken
        self.destTokenAmount = destTokenAmount
        self.destTokenAmountUsd = destTokenAmountUsd
        self.networkFee = networkFee
        self.platform = platform
        super.init()
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(srcToken, forKey: .srcToken)
        try container.encode(srcTokenAmount, forKey: .srcTokenAmount)
        try container.encode(srcTokenAmountUsd, forKey: .srcTokenAmountUsd)
        try container.encode(destToken, forKey: .destToken)
        try container.encode(destTokenAmount, forKey: .destTokenAmount)
        try container.encode(destTokenAmountUsd, forKey: .destTokenAmountUsd)
        try container.encode(networkFee, forKey: .networkFee)
        try container.encode(platform, forKey: .platform)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
