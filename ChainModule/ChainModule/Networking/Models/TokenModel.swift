//
//  TokenModel.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

struct TokenModel: Decodable {
    var address: String
    var symbol: String
    var name: String
    var decimals: Int
    var logo: String
    var tag: String
    var chainId: Int
}
