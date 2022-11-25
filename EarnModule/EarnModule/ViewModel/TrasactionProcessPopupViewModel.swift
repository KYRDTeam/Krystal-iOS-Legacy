//
//  TrasactionProcessPopupViewModel.swift
//  EarnModule
//
//  Created by Com1 on 16/11/2022.
//

import Foundation

protocol TrasactionProcessPopupViewModel: class {
    var destTitle: String { get }
    var hash: String { get }
    var description: String { get }
    var sourceIcon: String { get }
    var destIcon: String { get }
    var processingString: String { get }
    var finishButtonString: String { get }
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
}
