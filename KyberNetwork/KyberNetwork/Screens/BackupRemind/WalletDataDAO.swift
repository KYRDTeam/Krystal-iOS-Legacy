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
    
    func markWalletAsBackedUp(walletID: String) {
        guard let walletData = self.getWalletExtraData(walletID: walletID) else { return }
        let realm = try! Realm()
        try! realm.write {
            walletData.isBackedUp = true
            walletData.shouldRemindBackUp = false
        }
    }
    
}
