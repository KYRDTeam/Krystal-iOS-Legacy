//
//  TokenListResponse.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

struct TokenListResponse: Decodable {
    var tokens: [TokenModel]?
}
