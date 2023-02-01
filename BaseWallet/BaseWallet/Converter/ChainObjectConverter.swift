//
//  ChainObjectConverter.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

class ChainUrlConverter: Converter {
    typealias Input = ChainUrlObject
    typealias Output = ChainUrl
    
    static func convert(input: ChainUrlObject) -> ChainUrl {
        return ChainUrl(chainID: input.chainID, url: input.url, type: input.type)
    }
}

class ChainSmartContractConverter: Converter {
    typealias Input = ChainSmartContractObject
    typealias Output = ChainSmartContract
    
    static func convert(input: ChainSmartContractObject) -> ChainSmartContract {
        return ChainSmartContract(chainID: input.chainID, address: input.address, type: input.type)
    }
}

class ChainConfigConverter: Converter {
    typealias Input = ChainConfigObject
    typealias Output = ChainConfig
    
    static func convert(input: ChainConfigObject) -> ChainConfig {
        return ChainConfig(chainID: input.chainID, name: input.name, value: input.value)
    }
}
