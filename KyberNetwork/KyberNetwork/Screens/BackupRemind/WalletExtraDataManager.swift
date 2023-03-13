//
//  WalletExtraDataManager.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/03/2023.
//

import Foundation
import KrystalWallets
import AppState
import RealmSwift
import Dependencies

class WalletExtraDataManager {
    
    static let shared = WalletExtraDataManager()
    let dao = WalletDataDAO()
    
    func updateLastBackupRemindTime(walletID: String) {
        dao.updateLastBackupRemindTime(walletID: walletID)
    }
    
    func stopRemindBackup(walletID: String) {
        dao.stopRemind(walletID: walletID)
    }
    
    func markWalletBackedUp(walletID: String) {
        dao.markWalletAsBackedUp(walletID: walletID)
    }
    
    func shouldShowBackup(forWallet walletID: String) -> Bool {
        guard let walletData = dao.getWalletExtraData(walletID: walletID) else {
            return true
        }
        guard walletData.shouldRemindBackUp else {
            return false
        }
        let lastRemindTime = walletData.lastBackupRemindTime
        let startOfToDay = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let startOfRemindDay = Calendar.current.startOfDay(for: lastRemindTime).timeIntervalSince1970
        return startOfToDay - startOfRemindDay >= 86400
    }
    
    func migrateFromFile() {
        if AppSetting.shared.bool(forKey: migratedWalletBackupDataToRealm) {
            return
        }
        let extraDataList = WalletManager.shared.getAllWallets().map { wallet in
            return WalletExtraData(walletID: wallet.id,
                                   isBackedUp: AppState.shared.isWalletBackedUp(walletID: wallet.id),
                                   lastBackupRemindTime: Date(),
                                   shouldRemindBackUp: AppState.shared.isWalletBackedUp(walletID: wallet.id) == false)
        }
        let realm = try! Realm()
        try! realm.write {
            realm.add(extraDataList, update: .modified)
        }
        AppSetting.shared.set(value: true, forKey: migratedWalletBackupDataToRealm)
    }
    
}

extension WalletExtraDataManager: WalletManagerProtocol {
    
    func isWalletBackedUp(walletID: String) -> Bool {
        return dao.isWalletBackedUp(walletID: walletID)
    }
    
}
