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
                ChainConfigObject(chainID: chainModel.id, name: $0.name, value: $0.value)
            } ?? []
        }
        let urls = chainModels.flatMap { chainModel in
            return chainModel.urls?.map {
                ChainUrlObject(chainID: chainModel.id, url: $0.url, type: $0.type)
            } ?? []
        }
        let smartContracts = chainModels.flatMap { chainModel in
            return chainModel.smartContracts?.map {
                ChainSmartContractObject(chainID: chainModel.id, address: $0.address, type: $0.type)
            } ?? []
        }
        let chains = chainModels.map {
            return ChainObject(chainID: $0.id, name: $0.name, iconUrl: $0.logo, isDefault: $0.isDefault ?? false)
        }
        
        let realm = try! Realm()
        
        let newChainIDs = chainModels.map(\.id)
        
        let oldConfigs = realm.objects(ChainConfigObject.self).filter { config in
            return newChainIDs.contains(config.chainID)
        }
        
        let oldUrls = realm.objects(ChainUrlObject.self).filter { config in
            return newChainIDs.contains(config.chainID)
        }
        
        let oldSmartContracts = realm.objects(ChainSmartContractObject.self).filter { config in
            return newChainIDs.contains(config.chainID)
        }
        
        try! realm.write {
            realm.delete(oldConfigs)
            realm.delete(oldUrls)
            realm.delete(oldSmartContracts)
            realm.add(urls, update: .modified)
            realm.add(configs, update: .modified)
            realm.add(smartContracts, update: .modified)
            realm.add(chains, update: .modified)
        }
    }
    
}
