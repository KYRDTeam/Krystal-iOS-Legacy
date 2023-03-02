//
//  WalletDataManger.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/03/2023.
//

import Foundation
import RealmSwift

class WalletDataDAO {
    
    func getWalletExtraData(walletID: String) -> WalletExtraData? {
        let realm = try! Realm()
        return realm.object(ofType: WalletExtraData.self, forPrimaryKey: walletID)
    }
    
    func updateLastBackupRemindTime(walletID: String) {
        let walletData = WalletExtraData(walletID: walletID,
                                         isBackedUp: false,
                                         lastBackupRemindTime: Date(),
                                         shouldRemindBackUp: true)
        let realm = try! Realm()
        try! realm.write {
            realm.add(walletData, update: .modified)
        }
    }
    
    func isWalletBackedUp(walletID: String) -> Bool {
        return getWalletExtraData(walletID: walletID)?.isBackedUp ?? false
    }
    
    func markWalletAsBackedUp(walletID: String) {
        let walletData = WalletExtraData(walletID: walletID,
                                         isBackedUp: true,
                                         lastBackupRemindTime: Date(),
                                         shouldRemindBackUp: false)
        let realm = try! Realm()
        try! realm.write {
            realm.add(walletData, update: .modified)
        }
    }
    
    func stopRemind(walletID: String) {
        guard let walletData = self.getWalletExtraData(walletID: walletID) else { return }
        let realm = try! Realm()
        try! realm.write {
            walletData.shouldRemindBackUp = false
        }
    }
}
