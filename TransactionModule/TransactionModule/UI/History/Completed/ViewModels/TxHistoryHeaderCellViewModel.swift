//
//  TxHistoryHeaderCellViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import Services
import UIKit

struct TxHistoryHeaderCellViewModel {
    var typeIcon: UIImage?
    var chainIcon: String
    var typeString: String
    var contract: String
    var isSuccess: Bool
    var shouldHideChainIcon: Bool
    
    init(tx: TxRecord, isSelectedSpecificChain: Bool) {
        self.shouldHideChainIcon = isSelectedSpecificChain
        var type = TxRecordType(name: tx.contractInteraction?.methodName ?? "")
        chainIcon = tx.chain.chainLogo
        isSuccess = tx.status.isEmpty || tx.status.lowercased() == "success"
        
        if type == .contractInteraction {
            if tx.tokenApproval != nil {
                type = .approve
            } else if tx.tokenTransfers?.count == 1 {
                if tx.walletAddress == tx.from {
                    type = .transfer
                } else if tx.walletAddress == tx.to {
                    type = .receive
                }
            }
        }
        
        typeString = (tx.contractInteraction?.methodName ?? type.rawValue).capitalized
        typeIcon = type.icon
        
        switch type {
        case .transfer:
            contract = tx.to.shortTypeAddress
        case .receive:
            contract = tx.from.shortTypeAddress
        case .approve:
            let spenderName = tx.tokenApproval?.spenderName
            if spenderName.isNilOrEmpty {
                contract = tx.tokenApproval?.spenderAddress.shortTypeAddress ?? ""
            } else {
                contract = spenderName ?? ""
            }
        default:
            let contractName = tx.contractInteraction?.contractName
            if contractName.isNilOrEmpty {
                if tx.to.isEmpty {
                    contract = "-/-"
                } else {
                    contract = tx.to.shortTypeAddress
                }
            } else {
                contract = contractName ?? ""
            }
        }
    }
    
    
}
