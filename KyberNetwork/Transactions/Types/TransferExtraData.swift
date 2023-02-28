//
//  TransferExtraData.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
import TransactionModule

class TransferExtraData: TxTrackingExtraData {
    let token: String
    let tokenAmount: String
    let tokenAmountUsd: String
    let destAddress: String
    
    enum CodingKeys: String, CodingKey {
        case token, tokenAmount, tokenAmountUsd, destAddress
    }
    
    init(token: String, tokenAmount: String, tokenAmountUsd: String, destAddress: String) {
        self.token = token
        self.tokenAmount = tokenAmount
        self.tokenAmountUsd = tokenAmountUsd
        self.destAddress = destAddress
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
        try container.encode(destAddress, forKey: .destAddress)
    }
}
