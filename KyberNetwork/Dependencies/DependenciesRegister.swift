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
import TokenModule

class Dependencies {
  
  static func register() {
    AppDependencies.router = AppRouter()
    AppDependencies.tracker = AppTracker()
    AppDependencies.gasConfig = GasPriceManager.shared
    AppDependencies.priceStorage = AppPriceStorage()
    AppDependencies.nonceStorage = AppNonceStorage()
    AppDependencies.balancesStorage = AppBalanceStorage()
    AppDependencies.featureFlag = AppFeatureFlag()
    AppDependencies.tokenStorage = AppTokenStorage()
    
    TransactionManager.txProcessor = AppTxProcessor()
    
    ServiceConfig.platformWallet = Constants.platformWallet
    ServiceConfig.baseAPIURL = KNEnvironment.default.krystalEndpoint
    ServiceConfig.errorTracker = AppErrorTracker()
    
    NodeConfig.infuraKey = KNSecret.infuraKey
    NodeConfig.alchemyRopstenKey =  KNSecret.alchemyRopstenKey
    NodeConfig.nodeEndpoint = KNEnvironment.default.nodeEndpoint
    NodeConfig.solanaAppID = KNEnvironment.default.endpointName
    
    TokenModule.apiURL = KNEnvironment.default.krystalEndpoint
  }
  
}
