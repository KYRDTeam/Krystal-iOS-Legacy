//
//  ChainObserver.swift
//  ChainModule
//
//  Created by Tung Nguyen on 22/02/2023.
//

import Foundation
import RealmSwift

class ChainObserver: BackgroundWorker {
    
    var notificationToken: NotificationToken?
    
    override init() {
        super.init()
        
        start {
            let realm = try! Realm()
            let chainResults = realm.objects(ChainObject.self)
            self.notificationToken = chainResults.observe { change in
                switch change {
                case .update(_, _, let insertions, let modifications):
                    let insertedChains = insertions.map { chainResults[$0] }.compactMap { ChainDB.shared.getChain(byID: $0.id) }
                    let modifiedChains = modifications.map { chainResults[$0] }.compactMap { ChainDB.shared.getChain(byID: $0.id) }
                    NotificationCenter.default.post(name: .chainsChanged, object: nil, userInfo: [
                        "event": ChainListChangeEvent(insertions: insertedChains, modifications: modifiedChains, deletions: [])
                    ])
                default:
                    return
                }
            }
        }
    }
    
}
