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
import BaseWallet

class Dependencies {
    
    static func register() {
        AppDependencies.router = AppRouter()
        AppDependencies.tracker = AppTracker()
        AppDependencies.gasConfig = AppGasConfig()
        AppDependencies.priceStorage = AppPriceStorage()
        AppDependencies.nonceStorage = AppNonceStorage()
        
        ServiceConfig.baseAPIURL = KNEnvironment.default.krystalEndpoint
        ServiceConfig.errorTracker = AppErrorTracker()
      
        NodeConfig.infuraKey = KNSecret.infuraKey
        NodeConfig.alchemyRopstenKey =  KNSecret.alchemyRopstenKey
        NodeConfig.nodeEndpoint = KNEnvironment.default.nodeEndpoint
        NodeConfig.solanaAppID = KNEnvironment.default.endpointName
    }
    
}
