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
    static let appWalletsListHasUpdate = Notification.Name("kWalletListHasUpdateKey")
}

public class AppEventManager {
    
    public static let shared = AppEventManager()
    
    /// Change the current app selecting address
    /// - Parameter address: The address switch to
    public func switchAddress(address: KAddress) {
        NotificationCenter.default.post(name: .addressChanged, object: nil)
    }
    
}
