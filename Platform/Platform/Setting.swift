//
//  Setting.swift
//  Platform
//
//  Created by Tung Nguyen on 15/02/2023.
//

import Foundation
import RealmSwift

public let kSelectedChainID = "KEY_SELECTED_CHAIN_ID"
public let kIsSelectedAllNetworks = "KEY_IS_SELECTED_ALL_NETWORKS"
public let migratedWalletBackupDataToRealm = "MIGRATED_BACKUP_DATA_TO_REALM"

class AppSettingItem: Object {
    @Persisted var key: String = ""
    @Persisted var value: String = ""
    
    override static func primaryKey() -> String? {
        return "key"
    }
}

public class AppSetting {
    
    public static let shared = AppSetting()
    
    private init() {}
    
    public func int(forKey key: String) -> Int? {
        let realm = try! Realm()
        let value = realm.object(ofType: AppSettingItem.self, forPrimaryKey: key)?.value
        return value != nil ? Int(value!) : nil
    }
    
    public func bool(forKey key: String) -> Bool {
        let realm = try! Realm()
        let value = realm.object(ofType: AppSettingItem.self, forPrimaryKey: key)?.value
        return value == "true"
    }
    
    public func set(value: Any, forKey key: String) {
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
