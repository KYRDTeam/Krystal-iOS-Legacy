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
    
    init(data: [[String: String]]) {
        self.data = data
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
