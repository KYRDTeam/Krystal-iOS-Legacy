//
//  PriceStorage.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BigInt
import BaseWallet

public protocol PriceStorage {
    func price(tokenAddress: String, chain: ChainType) -> TokenPrice?
}
