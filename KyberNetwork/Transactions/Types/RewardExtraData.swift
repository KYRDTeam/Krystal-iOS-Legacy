//
//  RewardExtraData.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
import TransactionModule

class RewardExtraData: TxTrackingExtraData {
    let token: String
    let amount: String
    let amountUsd: String
    
    enum CodingKeys: String, CodingKey {
        case token, amount, amountUsd
    }
    
    init(token: String, amount: String, amountUsd: String) {
        self.token = token
        self.amount = amount
        self.amountUsd = amountUsd
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(amount, forKey: .amount)
        try container.encode(amount, forKey: .amount)
    }
}
