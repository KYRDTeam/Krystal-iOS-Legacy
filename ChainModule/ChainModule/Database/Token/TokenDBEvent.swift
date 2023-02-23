//
//  TokenDBChange.swift
//  ChainModule
//
//  Created by Tung Nguyen on 16/02/2023.
//

import Foundation

public extension Notification.Name {
    static let tokensChanged = Notification.Name("kNotificationTokensChanged")
    static let tokenBalancesChanged = Notification.Name("kNotificationTokenBalancesChanged")
    static let tokenPricesChanged = Notification.Name("kNotificationTokenPricesChanged")
}

public class TokenListChangedEvent {
    public var insertions: [Token]
    public var modifications: [Token]
    public var deletions: [Token]
    
    init(insertions: [Token], modifications: [Token], deletions: [Token]) {
        self.insertions = insertions
        self.modifications = modifications
        self.deletions = deletions
    }
}

public class TokenBalanceChangedEvent {
    public var changes: [TokenBalance]
    
    init(changes: [TokenBalance]) {
        self.changes = changes
    }
}
