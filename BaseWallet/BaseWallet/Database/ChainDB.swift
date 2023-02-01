//
//  ChainDB.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import RealmSwift

public class ChainDB {
    
    public func activeChains() -> [Chain] {
        return getListChains { lhs, rhs in
            return lhs.isAddedByUser
        } filterBy: { chain in
            return chain.isActive
        }
    }

    public func allChains() -> [Chain] {
        return getListChains { lhs, rhs in
            return lhs.isAddedByUser
        }
    }

    func getListChains(uniqueSortedBy: (Chain, Chain) -> Bool, filterBy: ((Chain) -> Bool)? = nil) -> [Chain] {
        let rawChainList = rawChainList()
        var chainIDs: [Int] = []
        for chain in rawChainList {
            if !chainIDs.contains(chain.id) {
                chainIDs.append(chain.id)
            }
        }
        let groupedChains = Dictionary.init(grouping: rawChainList) { $0.id }
        var uniqueChains: [Chain] = []
        for chainID in chainIDs {
            if let filterBy = filterBy {
                if let chain = groupedChains[chainID]?.sorted(by: uniqueSortedBy).first(where: filterBy) {
                    uniqueChains.append(chain)
                }
            } else {
                if let chain = groupedChains[chainID]?.sorted(by: uniqueSortedBy).first {
                    uniqueChains.append(chain)
                }
            }
        }
        return uniqueChains
    }

    public func rawChainList() -> [Chain] {
        return getChains().map {
            Chain(id: $0.id,
                  name: $0.name,
                  iconUrl: $0.iconUrl,
                  isActive: $0.isActive,
                  isDefault: $0.isDefault,
                  isAddedByUser: $0.isAddedByUser,
                  smartContracts: getSmartContracts(chainID: $0.id).map(ChainSmartContractConverter.convert),
                  urls: getUrls(chainID: $0.id).map(ChainUrlConverter.convert),
                  configs: getConfigs(chainID: $0.id).map(ChainConfigConverter.convert)
            )
        }
    }
    
    func getChains() -> [ChainObject] {
        let realm = try! Realm()
        return realm.objects(ChainObject.self).toArray()
    }
    
    func getSmartContracts(chainID: Int) -> [ChainSmartContractObject] {
        let realm = try! Realm()
        return realm.objects(ChainSmartContractObject.self).where { object in
            return object.chainID == chainID
        }.toArray()
    }
    
    func getConfigs(chainID: Int) -> [ChainConfigObject] {
        let realm = try! Realm()
        return realm.objects(ChainConfigObject.self).where { object in
            return object.chainID == chainID
        }.toArray()
    }
    
    func getUrls(chainID: Int) -> [ChainUrlObject] {
        let realm = try! Realm()
        return realm.objects(ChainUrlObject.self).where { object in
            return object.chainID == chainID
        }.toArray()
    }
    
}
