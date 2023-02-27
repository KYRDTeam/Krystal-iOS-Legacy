//
//  UnstakeTrackingExtraData.swift
//  EarnModule
//
//  Created by Tung Nguyen on 27/02/2023.
//

import Foundation
import TransactionModule

class UnstakingTrackingExtraData: TxTrackingExtraData {
    var token: String
    var tokenAmount: Double
    
    enum CodingKeys: String, CodingKey {
        case token, tokenAmount
    }
    
    init(token: String, tokenAmount: Double) {
        self.token = token
        self.tokenAmount = tokenAmount
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
    }
}
