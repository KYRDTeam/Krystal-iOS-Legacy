//
//  AppEvent.swift
//  AppState
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import BaseWallet
import KrystalWallets

public extension Notification.Name {
    static let appAddressChanged = Notification.Name("kAppDidChangeAddress")
    static let appChainChanged = Notification.Name("kChangeChainNotificationKey")
    static let appSelectAllChain = Notification.Name("kSelectAllChain")
    static let appWalletsListHasUpdate = Notification.Name("kWalletListHasUpdateKey")
}

public class AppEventManager {
    
    public static let shared = AppEventManager()
    
    /// Change the current app selecting address
    /// - Parameter address: The address switch to
    public func postSwitchAddressEvent(oldAddress: KAddress, address: KAddress, switchChain: Bool = false) {
        let userInfo: [String: Any] = ["switch_chain": switchChain, "old_address": oldAddress, "new_address": address]
        NotificationCenter.default.post(name: .appAddressChanged, object: nil, userInfo: userInfo)
    }
    
    public func postSwitchChainEvent(chain: ChainType) {
        NotificationCenter.default.post(name: .appChainChanged, object: nil)
    }
    
    public func postSelectAllChain() {
        NotificationCenter.default.post(name: .appSelectAllChain, object: nil)
    }
    
    public func postWalletListUpdatedEvent() {
        NotificationCenter.default.post(name: .appWalletsListHasUpdate, object: nil)
    }
    
}
