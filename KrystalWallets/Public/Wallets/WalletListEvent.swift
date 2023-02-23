//
//  WalletListEvent.swift
//  KrystalWallets
//
//  Created by Tung Nguyen on 17/02/2023.
//

import Foundation

public extension Notification.Name {
    static let walletsUpdated = Notification.Name("kNotificationWalletListUpdated")
}

public class WalletListEvent {
    public var insertions: [KAddress] = []
    public var modifications: [KAddress] = []
    public var deletions: [KAddress] = []
    
    public init(insertions: [KAddress], modifications: [KAddress], deletions: [KAddress]) {
        self.insertions = insertions
        self.modifications = modifications
        self.deletions = deletions
    }
}
