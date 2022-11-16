//
//  TrasactionProcessPopupViewModel.swift
//  EarnModule
//
//  Created by Com1 on 16/11/2022.
//

import Foundation

protocol TrasactionProcessPopupViewModel: class {
    var amountValue: String { get }
    var hash: String { get }
    var description: String { get }
    var sourceIcon: String { get }
    var destIcon: String { get }
    var processingString: String { get }
}

class StakingTransactionProcessPopupViewModel: TrasactionProcessPopupViewModel {
    let pendingStakingTx: PendingStakingTxInfo
    
    init(pendingStakingTx: PendingStakingTxInfo) {
        self.pendingStakingTx = pendingStakingTx
    }
    
    var amountValue: String {
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
}

class UnstakeTransactionProcessPopupViewModel: TrasactionProcessPopupViewModel {
    let pendingUnstakeTx: PendingUnstakeTxInfo
    
    init(pendingStakingTx: PendingUnstakeTxInfo) {
        self.pendingUnstakeTx = pendingStakingTx
    }
    
    var amountValue: String {
        return pendingUnstakeTx.platform.name.uppercased()
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
}
