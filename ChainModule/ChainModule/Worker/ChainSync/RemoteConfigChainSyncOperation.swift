//
//  RemoteConfigChainSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import FirebaseRemoteConfig

public class RemoteConfigChainSyncOperation: ChainSyncOperation {
    
    let remoteConfig = RemoteConfig.remoteConfig()
    
    override func execute(completion: @escaping () -> ()) {
        remoteConfig.fetch { _, error in
            self.remoteConfig.activate()
            ChainDB.shared.save(chainModels: self.getConfiguredChains())
            self.finish()
            completion()
        }
    }
    
    func getConfiguredChains() -> [ChainModel] {
        let data = remoteConfig.configValue(forKey: "chains").dataValue
        let chains = try? JSONDecoder().decode([ChainModel].self, from: data)
        return chains ?? []
    }
    
}
