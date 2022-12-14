//
//  PriceStorage.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BaseWallet

public protocol PriceStorage {
    func getQuoteUsdRate(chain: ChainType) -> Double?
    func getUsdPrice(address: String) -> Double?
}
