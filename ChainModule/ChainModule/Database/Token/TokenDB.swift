//
//  TokenDB.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import RealmSwift
import KrystalWallets

public class TokenDB {
    
    public static let shared = TokenDB()
    let tokenObserver = TokenObserver()
    
    public func getNativeToken(chainID: Int) -> Token? {
        return getToken(chainID: chainID, address: defaultNativeTokenAddress)
    }
    
    public func allTokens() -> [Token] {
        let realm = try! Realm()
        return realm.objects(TokenEntity.self).toArray().map(TokenEntityConverter.convert)
    }
    
    public func getTokens(chainID: Int) -> [Token] {
        let realm = try! Realm()
        return realm.objects(TokenEntity.self).where { $0.chainID == chainID }.toArray().map(TokenEntityConverter.convert)
    }
    
    public func allBalances() -> [TokenBalance] {
        let realm = try! Realm()
        return realm.objects(TokenBalanceEntity.self).toArray().map(TokenBalanceEntityConverter.convert)
    }
    
    public func search(chainID: Int, query: String) -> [Token] {
        let realm = try! Realm()
        let lowercasedQuery = query.lowercased()
        return realm.objects(TokenEntity.self)
            .filter("chainID == %@ AND (name contains[cd] %@ OR address contains[cd] %@ OR symbol contains[cd] %@)",
                    chainID, lowercasedQuery, lowercasedQuery, lowercasedQuery)
            .toArray()
            .map(TokenEntityConverter.convert)
    }
    
    public func getToken(chainID: Int, address: String) -> Token? {
        let realm = try! Realm()
        return (
            realm.object(ofType: TokenEntity.self, forPrimaryKey: "\(chainID)-\(address)-\(true)") ??
            realm.object(ofType: TokenEntity.self, forPrimaryKey: "\(chainID)-\(address)-\(false)")
        ).map(TokenEntityConverter.convert)
    }
    
    public func save(token: Token) {
        let realm = try! Realm()
        let tokenEntity = TokenEntity(chainID: token.chainID, address: token.address, iconUrl: token.iconUrl, decimal: token.decimal, symbol: token.symbol, name: token.name, tag: token.tag, type: token.type, isAddedByUser: token.isAddedByUser, isActive: true)
        try! realm.write {
            realm.add(tokenEntity, update: .modified)
        }
    }
    
    public func save(tokens: [TokenEntity]) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(tokens, update: .modified)
        }
    }
    
    @objc func onChainsChanged(notification: Notification) {
        guard let changes = notification.userInfo?["event"] as? ChainListChangeEvent else {
            return
        }
        let chains = changes.insertions + changes.modifications
        for chain in chains {
            TokenSyncWorker(chainID: chain.id).asyncWaitAll {
                print("TUNG", "Synced tokens for \(chain.name)")
            }
        }
    }
    
    public func removeAllTokens() {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(realm.objects(TokenEntity.self))
        }
    }
    
}
