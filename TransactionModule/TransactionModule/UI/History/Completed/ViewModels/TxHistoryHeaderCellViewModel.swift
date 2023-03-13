//
//  TxHistoryHeaderCellViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import Services
import UIKit
import BigInt

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
            } else if tx.tokenTransfers?.count == 1, let transferTx = tx.tokenTransfers?[0] {
                if (BigInt(transferTx.amount) ?? .zero) >= .zero {
                    type = .receive
                } else {
                    type = .transfer
                }
            }
        }
        
        typeString = (tx.contractInteraction?.methodName ?? type.rawValue).capitalized
        typeIcon = type.icon
        
        switch type {
        case .transfer:
            if let address = tx.tokenTransfers?.first?.otherAddress {
                contract = address.shortTypeAddress
            } else {
                contract = tx.to.shortTypeAddress
            }
        case .receive:
            if tx.from.isEmpty {
                contract = tx.tokenTransfers?.first?.otherAddress.shortTypeAddress ?? ""
            } else {
                contract = tx.from.shortTypeAddress
            }
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
