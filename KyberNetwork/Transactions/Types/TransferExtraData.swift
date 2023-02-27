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
}
