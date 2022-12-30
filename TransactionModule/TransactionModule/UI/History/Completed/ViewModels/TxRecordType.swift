//
//  TxRecordType.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import UIKit

enum TxRecordType {
    case swap
    case send
    case receive
    case multisend
    case earn
    case approve
    case claim
    case mint
    case bridge
    case contractInteract
    
    init(name: String) {
        switch name {
        case "swap":
            self = .swap
        case "transfer":
            self = .send
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
            self = .contractInteract
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .swap:
            return .txSwap
        case .send:
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
        case .contractInteract:
            return .txContractInteract
        }
    }
}
