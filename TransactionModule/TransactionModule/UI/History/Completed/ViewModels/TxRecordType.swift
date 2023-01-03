//
//  TxRecordType.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import UIKit

enum TxRecordType: String {
    case swap
    case transfer
    case receive
    case multisend
    case earn
    case approve
    case claim
    case mint
    case bridge
    case contractInteraction
    
    init(name: String) {
        switch name.lowercased() {
        case "swap":
            self = .swap
        case "transfer":
            self = .transfer
        case "receive":
            self = .receive
        case "multisend":
            self = .multisend
        case "stake":
            self = .earn
        case "approve":
            self = .approve
        case "claim":
            self = .claim
        case "mint":
            self = .mint
        case "bridge":
            self = .bridge
        default:
            self = .contractInteraction
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .swap:
            return .txSwap
        case .transfer:
            return .txSend
        case .receive:
            return .txReceive
        case .multisend:
            return .txMultisend
        case .earn:
            return .txEarn
        case .approve:
            return .txApprove
        case .claim:
            return .txClaim
        case .mint:
            return .txMint
        case .bridge:
            return .txBridge
        case .contractInteraction:
            return .txContractInteract
        }
    }
}
