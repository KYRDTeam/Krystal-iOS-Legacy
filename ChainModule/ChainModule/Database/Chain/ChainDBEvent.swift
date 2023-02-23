//
//  ChainDBEvent.swift
//  ChainModule
//
//  Created by Tung Nguyen on 16/02/2023.
//

import Foundation

public extension Notification.Name {
    static let chainsChanged = Notification.Name("kNotificationChainsChanged")
}

public class ChainListChangeEvent {
    public var insertions: [Chain]
    public var modifications: [Chain]
    public var deletions: [Chain]
    
    init(insertions: [Chain], modifications: [Chain], deletions: [Chain]) {
        self.insertions = insertions
        self.modifications = modifications
        self.deletions = deletions
    }
}
