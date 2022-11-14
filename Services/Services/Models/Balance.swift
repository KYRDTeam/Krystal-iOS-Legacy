//
//  Balance.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import BigInt
import Utilities

protocol BalanceProtocol {
    var value: BigInt { get }
    var amountShort: String { get }
    var amountFull: String { get }
}

public struct Balance: BalanceProtocol {

    public let value: BigInt

    init(value: BigInt) {
        self.value = value
    }

    var isZero: Bool {
        return value.isZero
    }

    var amountShort: String {
        return EtherNumberFormatter.short.string(from: value)
    }

    var amountFull: String {
        return EtherNumberFormatter.full.string(from: value)
    }
}
