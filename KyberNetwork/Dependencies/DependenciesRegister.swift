//
//  DependenciesRegister.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Dependencies
import Services
import AppState

class DependenciesRegister {
    
    static func register() {
        AppDependencies.router = AppRouter()
        AppDependencies.tracker = AppTracker()
        AppDependencies.gasConfig = AppGasConfig()
        
        ServiceConfig.baseAPIURL = KNEnvironment.default.krystalEndpoint
        ServiceConfig.errorTracker = AppErrorTracker()
    }
    
}
