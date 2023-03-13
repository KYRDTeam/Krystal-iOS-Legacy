//
//  AppRemoteConfig.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/03/2023.
//

import Foundation
import FirebaseRemoteConfig

class AppRemoteConfig {
    
    static let shared = AppRemoteConfig()
    
    func setup() {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = KNEnvironment.default == .production ? 3600 : 0
        remoteConfig.configSettings = settings
    }
    
}
