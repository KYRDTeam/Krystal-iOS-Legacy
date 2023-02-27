//
//  EarnTrackingExtraData.swift
//  EarnModule
//
//  Created by Tung Nguyen on 27/02/2023.
//

import Foundation
import TransactionModule

class EarnTrackingExtraData: TxTrackingExtraData {
    var token: String
    var tokenAmount: Double
    var tokenAmountUsd: Double
    
    enum CodingKeys: String, CodingKey {
        case token, tokenAmount, tokenAmountUsd
    }
    
    init(token: String, tokenAmount: Double, tokenAmountUsd: Double) {
        self.token = token
        self.tokenAmount = tokenAmount
        self.tokenAmountUsd = tokenAmountUsd
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(tokenAmount, forKey: .tokenAmount)
        try container.encode(tokenAmountUsd, forKey: .tokenAmountUsd)
    }
}
