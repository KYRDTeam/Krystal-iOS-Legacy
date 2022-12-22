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
    
    init(tx: TxRecord) {
        let type = TxRecordType(name: tx.contractInteraction?.methodName ?? "")
        typeIcon = type.icon
        typeString = tx.contractInteraction?.methodName ?? "Contract Interaction"
        chainIcon = tx.chain.chainLogo
        isSuccess = tx.status.isEmpty
        switch type {
        case .send:
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
                    contract = tx.walletAddress.shortTypeAddress
                } else {
                    contract = tx.to.shortTypeAddress
                }
            } else {
                contract = contractName ?? ""
            }
        }
    }
}
