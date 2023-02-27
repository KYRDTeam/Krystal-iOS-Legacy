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
    
    init(token: String, tokenAmount: String) {
        self.token = token
        self.tokenAmount = tokenAmount
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
