//
//  AppRouter.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import UIKit

public protocol AppRouterProtocol {
    func openWalletList()
    func openChainList()
    func createSwapViewController() -> UIViewController
}
