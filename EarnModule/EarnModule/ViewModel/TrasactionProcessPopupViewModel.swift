//
//  TrasactionProcessPopupViewModel.swift
//  EarnModule
//
//  Created by Com1 on 16/11/2022.
//

import Foundation
import Dependencies
import AppState

protocol TrasactionProcessPopupViewModel: class {
    var destTitle: String { get }
    var hash: String { get }
    var description: String { get }
    var sourceIcon: String { get }
    var destIcon: String { get }
    var processingString: String { get }
    var finishButtonString: String { get }
    func trackPopupOpenEvent()
}

class StakingTransactionProcessPopupViewModel: TrasactionProcessPopupViewModel {
    let pendingStakingTx: PendingStakingTxInfo
    let earningType: EarningType
    
    init(pendingStakingTx: PendingStakingTxInfo) {
        self.pendingStakingTx = pendingStakingTx
        self.earningType = .init(value: pendingStakingTx.platform.type)
    }
    
    var destTitle: String {
        return pendingStakingTx.platform.name.uppercased()
    }
    
    var hash: String {
        return pendingStakingTx.hash
    }
    
    var description: String {
        return pendingStakingTx.description
    }
    
    var sourceIcon: String {
        return pendingStakingTx.sourceIcon ?? ""
    }

    var destIcon: String {
        return pendingStakingTx.platform.logo
    }
    
    var processingString: String {
        switch earningType {
        case .staking:
            return Strings.stakingInProgress
        case .lending:
            return Strings.supplyingInProgress
        }
    }
    
    var finishButtonString: String {
        return Strings.viewMyPool
    }
  
    func trackPopupOpenEvent() {
        let params: [String : Any] = [
            "screenid": earningType == .staking ? "earn_v2_stake_done_pop_up" : "earn_v2_supply_done_pop_up",
            "txn_hash": pendingStakingTx.hash,
            "chain_id": pendingStakingTx.chain.getChainId()
            
        ]
      AppDependencies.tracker.track(
          earningType == .staking ? "earn_v2_stake_done_pop_up_open" : "earn_v2_supply_done_pop_up_open",
          properties: params
      )
    }
}

class UnstakeTransactionProcessPopupViewModel: TrasactionProcessPopupViewModel {
    let pendingUnstakeTx: PendingUnstakeTxInfo
    let earningType: EarningType
    
    init(pendingStakingTx: PendingUnstakeTxInfo) {
        self.pendingUnstakeTx = pendingStakingTx
        self.earningType = .init(value: pendingStakingTx.platform.type)
    }
    
    var destTitle: String {
        return pendingUnstakeTx.toTokenAmount + " " + ( pendingUnstakeTx.destSymbol ?? "" )
    }
    
    var hash: String {
        return pendingUnstakeTx.hash
    }
    
    var description: String {
        return pendingUnstakeTx.description
    }
    
    var sourceIcon: String {
        return pendingUnstakeTx.sourceIcon ?? ""
    }

    var destIcon: String {
        return pendingUnstakeTx.destIcon ?? ""
    }
    
    var processingString: String {
        switch earningType {
        case .staking:
            return Strings.unstakeInProgress
        case .lending:
            return Strings.withdrawInProgress
        }
    }
    
    var finishButtonString: String {
        return Strings.viewMyPortfolio
    }
  
    func trackPopupOpenEvent() {
        var params: [String: Any] =  ["screenid": earningType == .staking ? "earn_v2_unstake_done_pop_up" : "earn_v2_withdraw_done_pop_up"]
        params["txn_hash"] = hash
        params["chain_id"] = AppState.shared.currentChain.getChainId()
        AppDependencies.tracker.track(
            earningType == .staking ? "mob_unstake_done_pop_up_open" : "mob_withdraw_done_pop_up_open",
            properties: params
        )
    }
}
