//
//  GetL1Fee.swift
//  Services
//
//  Created by Com1 on 29/11/2022.
//

import Foundation

struct GetOPL1FeeEncode: Web3Request {
    typealias Response = String

    static let abi = "{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"_data\",\"type\":\"bytes\"}],\"name\":\"getL1Fee\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"}"

    let data: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.encodeFunctionCall(\(GetOPL1FeeEncode.abi), [\"\(data)\"])"
        return .script(command: run)
    }
}

struct GetOPL1FeeDecode: Web3Request {
    typealias Response = String

    let data: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.decodeParameter('uint256', '\(data)')"
        return .script(command: run)
    }
}
