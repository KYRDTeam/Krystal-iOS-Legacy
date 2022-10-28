//
//  TxSettingObject.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation

public enum GasType {
    case slow
    case regular
    case fast
    case superFast
}

public class TxSettingObject {
    var gasType: GasType = .regular
}
