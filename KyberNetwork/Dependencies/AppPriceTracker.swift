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
    
    func getQuoteUsdRate(chain: ChainType) -> Double? {
        return KNTrackerRateStorage.shared.getPriceWithAddress(chain.customRPC().quoteTokenAddress)?.usd
    }
    
}
