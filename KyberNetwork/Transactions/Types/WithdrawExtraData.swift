//
//  WithdrawExtraData.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
import TransactionModule

class WithdrawExtraData: TxTrackingExtraData {
    let token: String
    let tokenAmount: String
    
    enum CodingKeys: String, CodingKey {
        case token, tokenAmount
    }
    
    init(token: String, tokenAmount: String) {
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
