//
//  ChainDB+Model.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import RealmSwift

extension ChainDB {
    
    func save(chainModels: [ChainModel]) {
        let configs = chainModels.flatMap { chainModel in
            return chainModel.configs?.map {
                ChainConfigObject(chainID: chainModel.chainID, name: $0.name, value: $0.value)
            } ?? []
        }
        let urls = chainModels.flatMap { chainModel in
            return chainModel.urls?.map {
                ChainUrlObject(chainID: chainModel.chainID, url: $0.url, type: $0.type)
            } ?? []
        }
        let smartContracts = chainModels.flatMap { chainModel in
            return chainModel.smartContracts?.map {
                ChainSmartContractObject(chainID: chainModel.chainID, address: $0.address, type: $0.type)
            } ?? []
        }
        let chains = chainModels.map {
            return ChainObject(chainID: $0.chainID, name: $0.name, iconUrl: $0.iconUrl, isDefault: $0.isDefault)
        }
        
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(urls, update: .modified)
            realm.add(configs, update: .modified)
            realm.add(smartContracts, update: .modified)
            realm.add(chains, update: .modified)
        }
    }
    
}
