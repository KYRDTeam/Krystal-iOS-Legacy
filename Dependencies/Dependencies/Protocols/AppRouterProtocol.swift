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
import Services

public protocol AppRouterProtocol {
    func openWalletList(currentChain: ChainType, allowAllChainOption: Bool,
                        onSelectWallet: @escaping (KWallet) -> (),
                        onSelectWatchAddress: @escaping (KAddress) -> ())
    func openChainList(_ selectedChain: ChainType, allowAllChainOption: Bool, onSelectChain: @escaping (ChainType) -> Void)
    func openAddWallet()
    func openTransactionHistory()
    func openExternalURL(url: String)
    func openSupportURL()
    func openTxHash(txHash: String, chainID: Int)
    func openToken(navigationController: UINavigationController, address: String, chainID: Int)
    func openTokenTransfer(navigationController: UINavigationController, token: Token)
    func openSwap(token: Token)
    func openSwap()
    func openEarn()
    func openEarnPortfolio()
}
