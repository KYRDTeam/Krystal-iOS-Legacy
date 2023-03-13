//
//  TransferViewModel.swift
//  Transfer
//
//  Created by Tung Nguyen on 24/02/2023.
//

import Foundation
import ChainModule
import Utilities

class EVMTransferViewModel: TransferViewModelProtocol {
    
    var selectedToken: Observable<Token?> = .init(nil)
    var inputAmount: Observable<Double> = .init(0)
    var inputAddress: Observable<String> = .init("")
    
    init() {
        
    }
    
}
