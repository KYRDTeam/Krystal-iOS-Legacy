//
//  DefaultChainSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

public class DefaultChainSyncOperation: ChainSyncOperation {
    
    override func execute(completion: @escaping () -> ()) {
        let decoder = JSONDecoder()
        guard
            let url = Bundle(for: Self.self).url(forResource: "default_chains", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let chainModels = try? decoder.decode([ChainModel].self, from: data)
        else {
            completion()
            return
        }
        ChainDB.shared.save(chainModels: chainModels)
        completion()
    }
    
}
