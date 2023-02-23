//
//  TokenObserver.swift
//  ChainModule
//
//  Created by Tung Nguyen on 22/02/2023.
//

import Foundation
import RealmSwift

class TokenObserver: BackgroundWorker {
    
    var tokenChangeNotiToken: NotificationToken?
    
    override init() {
        super.init()
        
        start {
            let realm = try! Realm()
            let tokenResults = realm.objects(TokenEntity.self)
            self.tokenChangeNotiToken = tokenResults.observe({ event in
                switch event {
                case .update(_, _, let insertions, let modifications):
                    let insertedTokens = insertions.map { tokenResults[$0] }.compactMap { TokenDB.shared.getToken(chainID: $0.chainID, address: $0.address) }
                    let modifiedTokens = modifications.map { tokenResults[$0] }.compactMap { TokenDB.shared.getToken(chainID: $0.chainID, address: $0.address) }
                    NotificationCenter.default.post(name: .tokensChanged, object: nil, userInfo: [
                        "event": TokenListChangedEvent(insertions: insertedTokens, modifications: modifiedTokens, deletions: [])
                    ])
                default:
                    return
                }
            })
            NotificationCenter.default.addObserver(self, selector: #selector(self.onChainsChanged), name: .chainsChanged, object: nil)
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
    
}
