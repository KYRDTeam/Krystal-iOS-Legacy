//
//  TransactionSettingBasicTabViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import DesignSystem
import UIKit
import BigInt
import Dependencies
import AppState
import Utilities
import BaseWallet

class TransactionSettingBasicTabViewModel: BaseTransactionSettingTabViewModel {
    
    var settingObject: TxSettingObject
    
    init(gasConfig: GasConfig, settingObject: TxSettingObject, chain: ChainType) {
        self.settingObject = settingObject
        super.init(gasConfig: gasConfig, chain: chain)
    }
    
    func selectGasType(gasType: GasType) {
        if settingObject.basic == nil {
            settingObject = .init(basic: .init(gasType: gasType), advanced: nil)
        } else {
            settingObject.basic?.gasType = gasType
        }
    }
    
    func getGasOptionText(gasType: GasType) -> NSAttributedString {
        switch gasType {
        case .slow:
            return self.attributedString(for: gasConfig.lowGas, text: Strings.slow.uppercased())
        case .regular:
            return self.attributedString(for: gasConfig.standardGas, text: Strings.regular.uppercased())
        case .fast:
            return self.attributedString(for: gasConfig.fastGas, text: Strings.fast.uppercased())
        case .superFast:
            return self.attributedString(for: gasConfig.superFastGas, text: Strings.superFast.uppercased())
        }
    }
    
    func getEstimatedGasFee(gasType: GasType) -> String {
        let fee = getGasPrice(gasType: gasType) * gasLimit
        let feeString: String = NumberFormatUtils.gasFeeFormat(number: fee)
        let quoteToken = AppState.shared.currentChain.customRPC().quoteToken
        return "~ \(feeString) \(quoteToken)"
    }
    
    func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
        let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
        let gasPriceAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: AppTheme.current.primaryTextColor,
            NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 16),
            NSAttributedString.Key.kern: 0.0,
        ]
        let feeAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: AppTheme.current.secondaryTextColor,
            NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 12),
            NSAttributedString.Key.kern: 0.0,
        ]
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
        attributedString.append(NSAttributedString(string: " \(text)", attributes: feeAttributes))
        return attributedString
    }
    
    
}
