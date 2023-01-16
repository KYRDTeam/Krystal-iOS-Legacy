//
//  TxStatsCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 05/01/2023.
//

import Foundation
import BigInt
import Utilities

enum TxStatsCellType {
    case totalTx(Int)
    case totalGasFee(Double)
    case totalVolume(Double)
    
    var icon: UIImage? {
        switch self {
        case .totalTx:
            return .totalTx
        case .totalGasFee:
            return .totalGas
        case .totalVolume:
            return .totalVolume
        }
    }
    
    var title: String {
        switch self {
        case .totalTx:
            return Strings.totalTransaction
        case .totalGasFee:
            return Strings.totalGasFee
        case .totalVolume:
            return Strings.totalVolume
        }
    }
    
    var valueString: String {
        switch self {
        case .totalTx(let value):
            let bigIntValue = BigInt(Double(value) * pow(10, 18))
            return NumberFormatUtils.format(value: bigIntValue, decimals: 18, maxDecimalMeaningDigits: 0, maxDecimalDigits: 0)
        case .totalGasFee(let value):
            return NumberFormatUtils.billionBasedVolume(value: value)
        case .totalVolume(let value):
            return NumberFormatUtils.billionBasedVolume(value: value)
        }
    }
}
