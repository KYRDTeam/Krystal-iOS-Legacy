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
    
    func selectGasType(gasType: GasSpeed) {
        if setting.basic == nil {
            setting = .init(basic: .init(gasType: gasType), advanced: nil)
        } else {
            setting.basic?.gasType = gasType
        }
    }
    
    func getGasOptionText(gasType: GasSpeed) -> NSAttributedString {
        switch gasType {
        case .slow:
            return self.attributedString(for: gasConfig.getLowGasPrice(chain: chain), text: Strings.slow.uppercased())
        case .regular:
            return self.attributedString(for: gasConfig.getStandardGasPrice(chain: chain), text: Strings.regular.uppercased())
        case .fast:
            return self.attributedString(for: gasConfig.getFastGasPrice(chain: chain), text: Strings.fast.uppercased())
        case .superFast:
            return self.attributedString(for: gasConfig.getSuperFastGasPrice(chain: chain), text: Strings.superFast.uppercased())
        }
    }
    
    func getEstimatedGasFee(gasType: GasSpeed) -> String {
        let fee = getGasPrice(gasType: gasType) * gasLimit
        let feeString: String = NumberFormatUtils.gasFee(value: fee)
        let quoteToken = chain.customRPC().quoteToken
        return "~ \(feeString) \(quoteToken)"
    }
    
    func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
        let gasPriceString: String = NumberFormatUtils.gwei(value: gasPrice)
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
