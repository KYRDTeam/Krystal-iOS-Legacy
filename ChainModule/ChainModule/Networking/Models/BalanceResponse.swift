//
//  BaseResponse.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

struct BalanceResponse: Decodable {
    var data: [ChainBalanceModel]?
}
