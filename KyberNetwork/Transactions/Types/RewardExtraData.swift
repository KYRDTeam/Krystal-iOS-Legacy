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
    
    init(token: String, amount: String, amountUsd: String) {
        self.token = token
        self.amount = amount
        self.amountUsd = amountUsd
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
