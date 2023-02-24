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
        remoteConfig.fetchAndActivate { _, error in
            DispatchQueue.global().async {
                let chainModels = self.getConfiguredChains()
                let nativeTokens = chainModels.compactMap { chain -> TokenEntity? in
                    if let symbol = chain.nativeToken?.symbol {
                        return TokenEntity(chainID: chain.id,
                                           address: defaultNativeTokenAddress,
                                           iconUrl: "",
                                           decimal: 18,
                                           symbol: symbol,
                                           name: symbol,
                                           tag: "",
                                           type: nativeTokenType)
                    } else {
                        return nil
                    }
                }
                TokenDB.shared.save(tokens: nativeTokens)
                ChainDB.shared.save(chainModels: chainModels)
                self.finish()
                completion()
            }
        }
    }
    
    func getConfiguredChains() -> [ChainModel] {
        let data = remoteConfig.configValue(forKey: "chains").dataValue
        let chains = try? JSONDecoder().decode([ChainModel].self, from: data)
        return chains ?? []
    }
    
}
