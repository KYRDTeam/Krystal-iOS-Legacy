//
//  ClaimTxStatusViewModel.swift
//  EarnModule
//
//  Created by Tung Nguyen on 16/11/2022.
//

import Foundation
import TransactionModule
import Utilities
import BigInt
import UIKit
import AppState

class ClaimTxStatusViewModel {
    var status: TxStatus = .processing
    let pendingTx: PendingClaimTxInfo
    var isRewardClaim: Bool = false
    
    var onStatusUpdated: (() -> ())?
    
    init(pendingTx: PendingClaimTxInfo) {
        self.pendingTx = pendingTx
    }
    
    var statusString: String {
        switch status {
        case .processing:
            return Strings.claimInProgress
        case .success:
            return Strings.success
        case .failure:
            return Strings.txFailed
        }
    }
    
    var statusIcon: UIImage? {
        switch status {
        case .processing:
            return nil
        case .success:
            return UIImage(named: "tx_status_success")
        case .failure:
            return UIImage(named: "tx_status_fail")
        }
    }
    
    var isInProgress: Bool {
        switch status {
        case .processing:
            return true
        default:
            return false
        }
    }
    
    var tokenAmountString: String {
        let amount = BigInt(pendingTx.pendingUnstake.balance) ?? .zero
        return NumberFormatUtils.amount(value: amount, decimals: pendingTx.pendingUnstake.decimals) + " " + pendingTx.pendingUnstake.symbol
    }
    
    var tokenIcon: String {
        return pendingTx.pendingUnstake.logo
    }
    
    var hashString: String {
        return pendingTx.hash
    }
    
    var primaryButtonTitle: String {
        switch status {
        case .processing:
            if isRewardClaim {
                return AppState.shared.currentChain.customRPC().webScanName
            } else {
                return ChainType.make(chainID: pendingTx.pendingUnstake.chainID)?.customRPC().webScanName ?? ""
            }
        case .success:
            if isRewardClaim {
                return Strings.myReward
            } else {
                return Strings.myPortfolio
            }
            
        case .failure:
            return Strings.support
        }
    }
    
    var secondaryButtonTitle: String {
        return Strings.close
    }
    
    func updateStatus(status: TxStatus) {
        self.status = status
        onStatusUpdated?()
    }
    
}
