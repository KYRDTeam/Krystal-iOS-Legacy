//
//  MultisendExtraData.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
import TransactionModule

class MultisendExtraData: TxTrackingExtraData {
    let data: [[String: String]]
    let amountUsd: String
    enum CodingKeys: String, CodingKey {
        case data, amountUsd
    }
    
    init(data: [[String: String]], amountUsd: String) {
        self.data = data
        self.amountUsd = amountUsd
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(amountUsd, forKey: .amountUsd)
    }
}
