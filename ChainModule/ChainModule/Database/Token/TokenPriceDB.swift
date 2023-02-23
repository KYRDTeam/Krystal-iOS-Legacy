//
//  TokenPriceDB.swift
//  ChainModule
//
//  Created by Tung Nguyen on 17/02/2023.
//

import Foundation
import RealmSwift
import BigInt

public class TokenPriceDB {
    
    public static let shared = TokenPriceDB()
    
    private init() {
        initialize()
    }
    
    func initialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(onTokensChanged), name: .tokensChanged, object: nil)
    }
    
    public func getPrice(tokenAddress: String, chainID: Int) -> Double {
        let realm = try! Realm()
        let primaryKey = "\(chainID)-\(tokenAddress)"
        return realm.object(ofType: TokenPriceEntity.self, forPrimaryKey: primaryKey)
            .map(TokenPriceEntityConverter.convert)?
            .price ?? .zero
    }
    
    @objc func onTokensChanged(notification: Notification) {
        guard let changes = notification.userInfo?["event"] as? TokenListChangedEvent else {
            return
        }
        let tokens = changes.insertions + changes.modifications
        // TODO: Sync price
    }
    
}
