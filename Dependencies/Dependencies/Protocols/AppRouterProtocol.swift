//
//  AppRouter.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import UIKit
import BaseWallet
import KrystalWallets

public protocol AppRouterProtocol {
    func openWalletList(currentChain: ChainType, allowAllChainOption: Bool,
                        onSelectWallet: @escaping (KWallet) -> (),
                        onSelectWatchAddress: @escaping (KAddress) -> ())
    func openChainList(_ selectedChain: ChainType, allowAllChainOption: Bool, onSelectChain: @escaping (ChainType) -> Void)
    //  func createSwapViewController() -> UIViewController
    func createEarnOverViewController() -> UIViewController
    func openAddWallet()
    func openTransactionHistory()
    func openExternalURL(url: String)
    func openSupportURL()
    func openToken(symbol: String)
}
