//
//  AppPriceTracker.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import Dependencies
import BaseWallet

class AppPriceStorage: PriceStorage {
    func getUsdRate() -> Double? {
        return KNGeneralProvider.shared.quoteTokenPrice?.usd
    }
    
}
