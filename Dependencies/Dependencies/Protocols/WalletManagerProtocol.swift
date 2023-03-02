//
//  WalletManagerProtocol.swift
//  Dependencies
//
//  Created by Tung Nguyen on 02/03/2023.
//

import Foundation

public protocol WalletManagerProtocol {
    func isWalletBackedUp(walletID: String) -> Bool
}
