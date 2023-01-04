//
//  SettingBasicAdvancedFormCellModel.swift
//  SwapModule
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation
import BigInt
import Services
import Utilities
import Dependencies
import TransactionModule

class SettingBasicAdvancedFormCellModel {
    var gasLimit: BigInt
    var nonce: Int {
        didSet {
            self.nonceString = "\(self.nonce)"
        }
    }
    
    var customNonceValue: Int {
        return Int(nonceString) ?? 0
    }
    
    var gasPriceChangedHandler: (String) -> Void = { _ in }
    var gasLimitChangedHandler: (String) -> Void = { _ in }
    var nonceChangedHandler: (String) -> Void = { _ in }
    
    var tapTitleWithIndex: (Int) -> Void = { _ in }
    
    var gasPriceString: String = ""
    var gasLimitString: String = ""
    var nonceString: String = ""
    let rate: Rate?
    
    init(gasLimit: BigInt, nonce: Int, rate: Rate?) {
        self.rate = rate
        self.gasLimit = gasLimit
        self.nonce = nonce
        self.gasLimitString = gasLimit.description
    }
    
    var displayGasFee: String {
        var estTimeString = ""
        if let est = AppDependencies.gasConfig.currentChainStandardEstTime {
            estTimeString = " ~ \(est)s"
        }
        return "Standard " + NumberFormatUtils.gwei(value: AppDependencies.gasConfig.currentChainStandardGasPrice) + " GWEI" + estTimeString
    }
    
    func resetData() {
        gasPriceString = ""
        gasLimitString = gasLimit.description
        nonceString = "\(nonce)"
    }
    
    func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
        return ("", gasPriceString, gasLimitString)
    }
    
    var gasPriceErrorStatus: AdvancedInputError {
        guard !gasPriceString.isEmpty else {
            return .empty
        }
        let lowerLimit = KNSelectedGasPriceType.slow.getGasValue().string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
        let upperLimit = KNSelectedGasPriceType.superFast.getGasValue().string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
        let maxFeeDouble = gasPriceString.doubleValue
        
        if maxFeeDouble < lowerLimit {
            return .low
        } else if maxFeeDouble > upperLimit {
            return .high
        } else {
            return .none
        }
    }
    
    var advancedGasLimitErrorStatus: AdvancedInputError {
        guard !gasLimitString.isEmpty, let gasLimit = BigInt(gasLimitString) else {
            return .empty
        }
        let estGasUsed = self.rate?.estGasConsumed ?? Int(TransactionConstants.lowestGasLimit)
        
        if gasLimit < BigInt(estGasUsed) {
            return .low
        } else {
            return .none
        }
    }
    
    var advancedNonceErrorStatus: AdvancedInputError {
        guard !nonceString.isEmpty else {
            return .empty
        }
        
        let nonceInt = Int(nonceString) ?? 0
        if nonceInt < 0 {
            return .low
        } else {
            return .none
        }
    }
    
    func hasNoError() -> Bool {
        return gasPriceErrorStatus == .none && advancedGasLimitErrorStatus == .none && advancedNonceErrorStatus == .none
    }
}
