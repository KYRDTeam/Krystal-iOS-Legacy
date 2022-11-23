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
  //  func createSwapViewController() -> UIViewController
  func createEarnOverViewController() -> UIViewController
  func openAddWallet()
  func openTransactionHistory()
  func openExternalURL(url: String)
  func openSupportURL()
  func openTxHash(txHash: String, chainID: Int)
  func openToken(address: String, chainID: Int)
  func openTokenTransfer(token: Token)
  func openSwap(token: Token)
  func openInvest(token: Token)
  
}
