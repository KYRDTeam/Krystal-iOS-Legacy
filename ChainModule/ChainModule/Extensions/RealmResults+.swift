//
//  RealmResult+.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import RealmSwift

extension Results {
    
    func toArray() -> [Element] {
        return map { $0 }
    }
    
}
