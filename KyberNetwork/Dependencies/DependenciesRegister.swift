//
//  DependenciesRegister.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Dependencies

class DependenciesRegister {
    
    static func register() {
        AppDependencies.router = AppRouter()
    }
    
}
