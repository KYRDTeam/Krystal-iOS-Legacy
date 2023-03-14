//
//  TransferViewModel.swift
//  Transfer
//
//  Created by Tung Nguyen on 24/02/2023.
//

import Foundation
import ChainModule
import Utilities
import web3
import BigInt
import AppState
import KrystalWallets

class EVMTransferViewModel {

    var chainID: Int {
        return AppState.shared.selectedChainID
    }
    
    var currentAddress: KAddress {
        return AppState.shared.currentAddress
    }
    
    var token: Token?
    
    var receiverAddress: String = ""
    var worker: EthereumWorker!
    var amount: BigUInt = .zero
    
    init() {
        worker = EthereumWorker(clients: [])
    }
    
    func estimateGas(completion: @escaping () -> ()) {
        guard let token = token else { return }
        if token.isNativeToken {
            
        } else {
            let function = TransferToken(contract: <#T##EthereumAddress#>,
                                         walletAddress: <#T##EthereumAddress#>,
                                         token: <#T##EthereumAddress#>,
                                         to: <#T##EthereumAddress#>,
                                         amount: amount,
                                         data: Data())
            worker.eth_estimateGas(try! function.transaction()) { result in
                
            }
        }
        
    }
    
}
