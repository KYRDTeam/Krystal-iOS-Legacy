//
//  TokenBalanceDB.swift
//  ChainModule
//
//  Created by Tung Nguyen on 16/02/2023.
//

import Foundation
import RealmSwift
import KrystalWallets
import BigInt

public class TokenBalanceDB: BackgroundWorker {
    
    public static let shared = TokenBalanceDB()
    
    private override init() {
        super.init()
        initialize()
    }
    
    func initialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onTokensChanged), name: .tokensChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onWalletsChanged), name: .walletsUpdated, object: nil)
    }
    
    public func getBalance(tokenAddress: String, chainID: Int, walletAddress: String) -> BigInt {
        let realm = try! Realm()
        let primaryKey = "\(chainID)-\(tokenAddress)-\(walletAddress)"
        return realm.object(ofType: TokenBalanceEntity.self, forPrimaryKey: primaryKey)
            .map(TokenBalanceEntityConverter.convert)?
            .balance ?? .zero
    }
    
    @objc func onWalletsChanged(notification: Notification) {
        guard let changes = notification.userInfo?["event"] as? WalletListEvent else {
            return
        }
        changes.deletions.forEach { address in
            self.remove(walletAddress: address.addressString)
        }
        let tokens = TokenDB.shared.allTokens()
        changes.insertions.forEach { address in
            BalanceSyncWorker(tokens: tokens, address: address).asyncWaitAll()
        }
    }
    
    @objc func onTokensChanged(notification: Notification) {
        guard let changes = notification.userInfo?["event"] as? TokenListChangedEvent else {
            return
        }
        let tokens = changes.insertions + changes.modifications
        let addresses = WalletManager.shared.getAllAddresses()
        addresses.forEach { address in
            BalanceSyncWorker(tokens: tokens, address: address).asyncWaitAll()
        }
    }
    
    public func syncBalance(wallet: KWallet) {
        let tokens = TokenDB.shared.allTokens()
        let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
        addresses.forEach { address in
            BalanceSyncWorker(tokens: tokens, address: address).asyncWaitAll()
        }
    }
    
    func save(balance: TokenBalanceEntity) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(balance, update: .modified)
        }
        NotificationCenter.default.post(name: .tokenBalancesChanged, object: self, userInfo: [
            "event": TokenBalanceChangedEvent(changes: [TokenBalanceEntityConverter.convert(input: balance)])
        ])
    }
    
    func save(balances: [TokenBalanceEntity]) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(balances, update: .modified)
        }
        NotificationCenter.default.post(name: .tokenBalancesChanged, object: self, userInfo: [
            "event": TokenBalanceChangedEvent(changes: balances.map(TokenBalanceEntityConverter.convert))
        ])
    }
    
    func remove(walletAddress: String) {
        let realm = try! Realm()
        let balances = realm.objects(TokenBalanceEntity.self).where { $0.walletAddress == walletAddress }
        try! realm.write {
            realm.delete(balances)
        }
    }
    
}
