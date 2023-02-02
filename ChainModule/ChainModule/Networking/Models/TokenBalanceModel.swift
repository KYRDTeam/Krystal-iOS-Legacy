//
//  TokenBalanceModel.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

struct TokenBalanceModel: Decodable {
    struct Token: Decodable {
        var address: String
    }
    var token: Token
    var balance: String
    var userAddress: String
}

