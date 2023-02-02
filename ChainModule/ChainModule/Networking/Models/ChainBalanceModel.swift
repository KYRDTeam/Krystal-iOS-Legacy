//
//  ChainBalanceModel.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

struct ChainBalanceModel: Decodable {
    var chainId: Int
    var balances: [TokenBalanceModel]
}
