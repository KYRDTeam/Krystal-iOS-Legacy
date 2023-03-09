//
//  VersionStatus.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/03/2023.
//

import Foundation

enum VersionStatus: String {
    case maintainance
    case canUpdate = "can_update"
    case mustUpdate = "must_update"
    case normal
    
    init(value: String) {
        self = .init(rawValue: value) ?? .normal
    }
}
