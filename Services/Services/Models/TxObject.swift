//
//  TxObject.swift
//  Services
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation

public struct TransactionResponse: Codable {
    public let timestamp: Int?
    public let error: String?
    public let txObject: TxObject
}

public struct TxObject: Codable {
    public var nonce: String
    public let from, to, data, value: String
    public let gasPrice, gasLimit: String
    public init(nonce: String, from: String, to: String, data: String, value: String, gasPrice: String, gasLimit: String) {
        self.nonce = nonce
        self.from = from
        self.to = to
        self.data = data
        self.value = value
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
    }
}
