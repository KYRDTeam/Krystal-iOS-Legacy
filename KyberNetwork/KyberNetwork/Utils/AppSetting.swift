//
//  AppSetting.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/03/2023.
//

import Foundation
import RealmSwift

let migratedWalletBackupDataToRealm = "MIGRATED_BACKUP_DATA_TO_REALM"

class AppSettingItem: Object {
    @Persisted var key: String = ""
    @Persisted var value: String = ""
    
    override static func primaryKey() -> String? {
        return "key"
    }
}

class AppSetting {
    
    static let shared = AppSetting()
    
    func int(forKey key: String) -> Int? {
        let realm = try! Realm()
        let value = realm.object(ofType: AppSettingItem.self, forPrimaryKey: key)?.value
        return value != nil ? Int(value!) : nil
    }
    
    func bool(forKey key: String) -> Bool {
        let realm = try! Realm()
        let value = realm.object(ofType: AppSettingItem.self, forPrimaryKey: key)?.value
        return value == "true"
    }
    
    func set(value: Any, forKey key: String) {
        let realm = try! Realm()
        
        if let item = realm.object(ofType: AppSettingItem.self, forPrimaryKey: key) {
            try! realm.write {
                item.value = "\(value)"
            }
        } else {
            let item = AppSettingItem()
            item.key = key
            item.value = "\(value)"
            try! realm.write {
                realm.add(item)
            }
        }
    }
    
}

