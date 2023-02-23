//
//  TokenBalanceLabel.swift
//  TokenModule
//
//  Created by Tung Nguyen on 20/02/2023.
//

import Foundation
import ChainModule
import UIKit
import BigInt
import Utilities

public class TokenBalanceLabel: UILabel {
    
    var tokenAddress: String?
    var chainID: Int?
    var walletAddress: String?
    
    func setBalance(balance: BigInt, decimals: Int) {
        if let tokenAddress = tokenAddress, let chainID = chainID, let token = TokenDB.shared.getToken(chainID: chainID, address: tokenAddress) {
            DispatchQueue.main.async {
                self.text = NumberFormatUtils.balanceFormat(value: balance, decimals: decimals) + " " + token.symbol
            }
        }
    }
    
    public func observe(tokenAddress: String, chainID: Int, walletAddress: String) {
        NotificationCenter.default.removeObserver(self, name: .tokenBalancesChanged, object: nil)
        self.chainID = chainID
        self.tokenAddress = tokenAddress
        self.walletAddress = walletAddress
        self.reloadBalance(tokenAddress: tokenAddress, chainID: chainID, walletAddress: walletAddress)
        NotificationCenter.default.addObserver(self, selector: #selector(onBalancesUpdated), name: .tokenBalancesChanged, object: nil)
    }
    
    @objc func onBalancesUpdated(notification: Notification) {
        guard let event = notification.userInfo?["event"] as? TokenBalanceChangedEvent else {
            return
        }
        guard let tokenAddress = tokenAddress, let chainID = chainID, let walletAddress = walletAddress else {
            return
        }
        if event.changes.contains(where: { $0.chainID == chainID && $0.tokenAddress == tokenAddress && $0.walletAddress == walletAddress }) {
            reloadBalance(tokenAddress: tokenAddress, chainID: chainID, walletAddress: walletAddress)
        }
    }
    
    func reloadBalance(tokenAddress: String, chainID: Int, walletAddress: String) {
        if let token = TokenDB.shared.getToken(chainID: chainID, address: tokenAddress) {
            let balance = TokenBalanceDB.shared.getBalance(tokenAddress: tokenAddress, chainID: chainID, walletAddress: walletAddress)
            setBalance(balance: balance, decimals: token.decimal)
        }
    }
    
}
