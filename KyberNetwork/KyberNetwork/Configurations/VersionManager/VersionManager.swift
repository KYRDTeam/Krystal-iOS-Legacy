//
//  VersionManager.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/03/2023.
//

import Foundation
import FirebaseRemoteConfig

class VersionManager {
    
    static let shared = VersionManager()
    var remoteConfig: RemoteConfig!
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
    }
    
    func getCurrentVersionStatus() -> VersionStatus {
        let data = remoteConfig.configValue(forKey: "version_config").dataValue
        return (try? JSONDecoder().decode(VersionConfig.self, from: data).status) ?? .normal
    }
    
    func getLatestVersionConfig() -> VersionConfig? {
        let data = remoteConfig.configValue(forKey: "latest_version").dataValue
        return try? JSONDecoder().decode(VersionConfig.self, from: data)
    }
    
}
