//
//  TxObject.swift
//  Services
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation

public struct TxObject: Codable {
    public var nonce: String
    public let from, to, data, value: String
    public let gasPrice, gasLimit: String
}
