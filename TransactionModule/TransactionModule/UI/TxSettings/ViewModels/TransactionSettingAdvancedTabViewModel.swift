//
//  TransactionSettingAdvancedTabViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import Dependencies
import BaseWallet

class TransactionSettingAdvancedTabViewModel: BaseTransactionSettingTabViewModel {
    
    var settingObject: TxSettingObject
    
    init(gasConfig: GasConfig, settingObject: TxSettingObject, chain: ChainType) {
        self.settingObject = settingObject
        super.init(gasConfig: gasConfig, chain: chain)
    }
    
    
    
}
