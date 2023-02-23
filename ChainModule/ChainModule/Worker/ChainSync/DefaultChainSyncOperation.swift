//
//  DefaultChainSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import Platform

public class DefaultChainSyncOperation: ChainSyncOperation {
    
    override func execute(completion: @escaping () -> ()) {
        let decoder = JSONDecoder()
        guard
            let url = Bundle(for: Self.self).url(forResource: "default_chains", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            completion()
            return
        }
        let chainModels = try! decoder.decode([ChainModel].self, from: data)
        let nativeTokens = chainModels.compactMap { chain -> TokenEntity? in
            if let symbol = chain.nativeToken?.symbol {
                return TokenEntity(chainID: chain.id, address: defaultNativeTokenAddress, iconUrl: "", decimal: 18, symbol: symbol, name: "", tag: "", type: nativeTokenType)
            } else {
                return nil
            }
        }
        TokenDB.shared.save(tokens: nativeTokens)
        ChainDB.shared.save(chainModels: chainModels)
        completion()
    }
    
}
