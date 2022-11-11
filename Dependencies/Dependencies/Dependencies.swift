//
//  Dependencies.swift
//  Dependencies
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation

public class AppDependencies {
    public static var tracker: TrackerProtocol!
    public static var gasConfig: GasConfig!
    public static var router: AppRouterProtocol!
    public static var tokenStorage: TokenStorage!
    public static var nonceStorage: NonceStorage!
    public static var priceStorage: PriceStorage!
    public static var balancesStorage: BalancesStorage!
}
