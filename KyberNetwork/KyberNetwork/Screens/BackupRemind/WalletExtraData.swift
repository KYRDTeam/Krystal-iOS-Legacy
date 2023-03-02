//
//  WalletExtraData.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/03/2023.
//

import Foundation
import RealmSwift

class WalletExtraData: Object {
    @Persisted var walletID: String = ""
    @Persisted var isBackedUp: Bool = false
    @Persisted var lastBackupRemindTime: Date = Date()
    @Persisted var shouldRemindBackUp: Bool = true
    
    override class func primaryKey() -> String? {
        return "walletID"
    }
    
    init(walletID: String, isBackedUp: Bool, lastBackupRemindTime: Date, shouldRemindBackUp: Bool) {
        self.walletID = walletID
        self.isBackedUp = isBackedUp
        self.lastBackupRemindTime = lastBackupRemindTime
        self.shouldRemindBackUp = shouldRemindBackUp
    }
}
