//
//  TokenDB.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import RealmSwift

public class TokenDB {
    
    public static let shared = TokenDB()
    var chainChangeNotiToken: NotificationToken?
    var tokenChangeNotiToken: NotificationToken?
    
    private init() {
        observeChainDB()
    }
    
    func allTokens() -> [Token] {
        let realm = try! Realm()
        return realm.objects(TokenEntity.self).toArray().map(TokenEntityConverter.convert)
    }
    
    func allBalances() -> [TokenBalance] {
        let realm = try! Realm()
        return realm.objects(TokenBalanceEntity.self).toArray().map(TokenBalanceEntityConverter.convert)
    }
    
    func getToken(chainID: Int, address: String) -> Token? {
        let realm = try! Realm()
        return (
            realm.object(ofType: TokenEntity.self, forPrimaryKey: "\(chainID)-\(address)-\(true)") ??
            realm.object(ofType: TokenEntity.self, forPrimaryKey: "\(chainID)-\(address)-\(false)")
        ).map(TokenEntityConverter.convert)
    }
    
    func save(tokens: [TokenEntity]) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(tokens, update: .modified)
        }
    }
    
    func save(balance: TokenBalanceEntity) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(balance, update: .modified)
        }
    }
    
    func save(balances: [TokenBalanceEntity]) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(balances, update: .modified)
        }
    }
    
    func observeChainDB() {
        let realm = try! Realm()
        let chainResults = realm.objects(ChainObject.self)
        chainChangeNotiToken = chainResults.observe { change in
            switch change {
            case .update(let chains, _, _, _):
                let newChains = ChainDB.shared.allChains()
                for chain in newChains {
                    TokenSyncWorker(chainID: chain.id).asyncWaitAll {
                        print("TUNGG", "Synced tokens for \(chain.name)")
                    }
                }
            default:
                return
            }
        }
        let tokenResults = realm.objects(TokenEntity.self)
        tokenChangeNotiToken = tokenResults.observe({ event in
            switch event {
            case .update(let tokenResults, _, _, _):
                BalanceSyncWorker(tokens: tokenResults.toArray().map(TokenEntityConverter.convert), address: "0x8d61ab7571b117644a52240456df66ef846cd999").asyncWaitAll {
                    print("TUNGG", "Synced balances for \(tokenResults.count) tokens")
                }
            default:
                return
            }
        })
    }
    
    public func removeAllTokens() {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(realm.objects(TokenEntity.self))
        }
    }
    
}
