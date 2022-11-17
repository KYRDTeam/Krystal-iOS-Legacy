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
    
    init(pendingStakingTx: PendingStakingTxInfo) {
        self.pendingStakingTx = pendingStakingTx
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
        return pendingStakingTx.destIcon ?? ""
    }
    
    var processingString: String {
        return Strings.stakingInProgress
    }
    
    var finishButtonString: String {
        return Strings.viewMyPool
    }
}

class UnstakeTransactionProcessPopupViewModel: TrasactionProcessPopupViewModel {
    let pendingUnstakeTx: PendingUnstakeTxInfo
    
    init(pendingStakingTx: PendingUnstakeTxInfo) {
        self.pendingUnstakeTx = pendingStakingTx
    }
    
    var destTitle: String {
        return pendingUnstakeTx.sourceSymbol ?? ""
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
        return Strings.unstakeInProgress
    }
    
    var finishButtonString: String {
        return Strings.viewMyPortfolio
    }
}
