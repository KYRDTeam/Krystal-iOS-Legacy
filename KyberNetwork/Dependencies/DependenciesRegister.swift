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
import TransactionModule

class Dependencies {
    
    static func register() {
        AppDependencies.router = AppRouter()
        AppDependencies.tracker = AppTracker()
        AppDependencies.gasConfig = GasPriceManager.shared
        AppDependencies.priceStorage = AppPriceStorage()
        AppDependencies.nonceStorage = AppNonceStorage()
        AppDependencies.balancesStorage = AppBalanceStorage()
        
        ServiceConfig.baseAPIURL = KNEnvironment.default.krystalEndpoint
        ServiceConfig.errorTracker = AppErrorTracker()
      
        NodeConfig.infuraKey = KNSecret.infuraKey
        NodeConfig.alchemyRopstenKey =  KNSecret.alchemyRopstenKey
        NodeConfig.nodeEndpoint = KNEnvironment.default.nodeEndpoint
        NodeConfig.solanaAppID = KNEnvironment.default.endpointName
        
        TransactionManager.txProcessor = AppTxProcessor()
    }
    
}
