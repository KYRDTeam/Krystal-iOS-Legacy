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
  func openChainList(allowAllChainOption: Bool)
  func createSwapViewController() -> UIViewController
}
