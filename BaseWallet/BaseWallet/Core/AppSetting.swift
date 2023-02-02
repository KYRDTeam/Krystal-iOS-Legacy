//
//  AppSetting.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 31/01/2023.
//

import Foundation
import RealmSwift

class AppSettingItem: Object {
    @Persisted var key: String = ""
    @Persisted var value: String = ""
    
    public override static func primaryKey() -> String? {
        return "key"
    }
}

class AppSettingManager {
    
    func bool(forKey key: String) -> Bool {
        let realm = try! Realm()
        let value = realm.object(ofType: AppSettingItem.self, forPrimaryKey: key)?.value
        return value == "true"
    }
    
    func set(value: Bool, forKey key: String) {
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
