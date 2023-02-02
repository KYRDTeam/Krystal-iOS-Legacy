//
//  ChainModel.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

struct ChainModel: Decodable {
    var chainID: Int
    var name: String
    var iconUrl: String
    var isDefault: Bool
    var configs: [ChainConfigModel]?
    var smartContracts: [ChainSmartContractModel]?
    var urls: [ChainUrlModel]?
}

struct ChainConfigModel: Decodable {
    var name: String
    var value: String
}

struct ChainSmartContractModel: Decodable {
    var address: String
    var type: String
}

struct ChainUrlModel: Decodable {
    var url: String
    var type: String
    var name: String
}
