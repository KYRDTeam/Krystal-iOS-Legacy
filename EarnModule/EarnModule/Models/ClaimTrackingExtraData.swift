//
//  ClaimTrackingExtraData.swift
//  EarnModule
//
//  Created by Tung Nguyen on 27/02/2023.
//

import Foundation
import TransactionModule

class ClaimTrackingExtraData: TxTrackingExtraData {
    var token: String
    var amount: Double
    var amountUsd: Double
    
    enum CodingKeys: String, CodingKey {
        case token, amount, amountUsd
    }
    
    init(token: String, amount: Double, amountUsd: Double) {
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
        try container.encode(amountUsd, forKey: .amountUsd)
    }
}
