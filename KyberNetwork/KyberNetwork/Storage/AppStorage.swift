//
//  AppStorage.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 11/01/2023.
//

import Foundation

class AppStorage {
    
    static let shared = AppStorage()
    
    private init() {}
    
    var isAppOpenedBefore: Bool {
        let valueInUserDefaults = UserDefaults.standard.bool(forKey: Constants.isAppOpenAlready)
        let valueInStorage = Storage.retrieve(Constants.isAppOpenAlready, as: Bool.self) ?? false
        return valueInUserDefaults || valueInStorage
    }
    
    func markAppAsOpenedBefore() {
        UserDefaults.standard.set(true, forKey: Constants.isAppOpenAlready)
        Storage.store(true, as: Constants.isAppOpenAlready)
    }
    
}
