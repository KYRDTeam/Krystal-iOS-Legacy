//
//  TransactionSettingsViewModel.swift
//  SwapModule
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation
import BigInt
import Services
import AppState
import Utilities
import BaseWallet

typealias BasicSettingsInfo = (type: KNSelectedGasPriceType, value: BigInt)
typealias AdvancedSettingsInfo = (maxPriority: String, maxFee: String, gasLimit: String)

class TransactionSettingsViewModel {
    var isAdvancedMode = false
    var isExpertMode = false {
        didSet {
            self.expertModeSwitchChangeStatusHandler(self.isExpertMode)
        }
    }
    
    var gasLimit: BigInt
    var gasPrice: BigInt
    var basicSelectedType: KNSelectedGasPriceType
    
    var nonce: Int = -1 {
        didSet {
            self.basicAdvancedCellModel.nonce = self.nonce
            self.advancedModeCellModel.nonce = self.nonce
        }
    }
    
    var quoteTokenDetail: TokenDetailInfo?
    let slippageCellModel = SlippageRateCellModel()
    let segmentedCellModel = SettingSegmentedCellModel()
    let switchExpertMode = SettingExpertModeSwitchCellModel()
    let basicModeCellModel = SettingBasicModeCellModel()
    let basicAdvancedCellModel: SettingBasicAdvancedFormCellModel
    let advancedModeCellModel: SettingAdvancedModeFormCellModel
    
    var switchExpertModeEventHandler: (Bool) -> Void = { _ in }
    var switchAdvancedModeEventHandle: (Bool) -> Void = { _ in }
    var slippageChangedEventHandler: (Double) -> Void = { _ in }
    var expertModeSwitchChangeStatusHandler: (Bool) -> Void = { _ in }
    var advancedSettingValueChangeHander: () -> Void = {}
    var saveEventHandler: (SwapTransactionSettings) -> Void = { _ in }
    var titleLabelTappedWithIndex: (Int) -> Void = { _ in }
    
    let chain: ChainType
    
    init(chain: ChainType, gasLimit: BigInt, selectType: KNSelectedGasPriceType = .medium, rate: Rate?, defaultOpenAdvancedMode: Bool) {
        self.chain = chain
        self.gasPrice = selectType.getGasValue()
        self.gasLimit = gasLimit
        self.basicSelectedType = selectType
        self.isAdvancedMode = defaultOpenAdvancedMode
        
        self.basicModeCellModel.gasLimit = gasLimit
        self.basicModeCellModel.rate = rate
        switch self.basicSelectedType {
        case .fast:
            basicModeCellModel.selectedIndex = 3
        case .medium:
            basicModeCellModel.selectedIndex = 2
        case .slow:
            basicModeCellModel.selectedIndex = 1
        default:
            basicModeCellModel.selectedIndex = -1
        }
        self.basicAdvancedCellModel = SettingBasicAdvancedFormCellModel(gasLimit: gasLimit, nonce: -1, rate: rate)
        self.advancedModeCellModel = SettingAdvancedModeFormCellModel(gasLimit: gasLimit, nonce: -1, rate: rate)
        
        self.segmentedCellModel.selectedIndex = isAdvancedMode ? 1 : 0
        self.segmentedCellModel.valueChangeHandler = { value in
            self.isAdvancedMode = value == 1
            self.switchAdvancedModeEventHandle(self.isAdvancedMode)
        }
        self.switchExpertMode.switchValueChangedHandle = { value in
            self.isExpertMode = value
            self.switchExpertModeEventHandler(value)
        }
        
        self.basicModeCellModel.actionHandler = { value in
            switch value {
            case 3:
                self.basicSelectedType = .fast
            case 2:
                self.basicSelectedType = .medium
            case 1:
                self.basicSelectedType = .slow
            default:
                break
            }
            self.gasPrice = self.basicSelectedType.getGasValue()
        }
        
        self.basicAdvancedCellModel.gasPriceChangedHandler = { value in
            self.advancedSettingValueChangeHander()
        }
        
        self.basicAdvancedCellModel.gasLimitChangedHandler = { value in
            self.advancedSettingValueChangeHander()
        }
        
        self.basicAdvancedCellModel.nonceChangedHandler = { value in
            self.advancedSettingValueChangeHander()
        }
        
        self.advancedModeCellModel.maxPriorityFeeChangedHandler = { value in
            self.advancedSettingValueChangeHander()
        }
        
        self.advancedModeCellModel.maxFeeChangedHandler = { value in
            self.advancedSettingValueChangeHander()
        }
        
        self.advancedModeCellModel.gasLimitChangedHandler = { value in
            self.advancedSettingValueChangeHander()
        }
        
        self.advancedModeCellModel.customNonceChangedHander = { value in
            self.advancedSettingValueChangeHander()
        }
        
        self.slippageCellModel.slippageChangedEvent = { value in
            self.slippageChangedEventHandler(value)
        }
        
        basicAdvancedCellModel.tapTitleWithIndex = { value in
            self.titleLabelTappedWithIndex(value)
        }
        
        advancedModeCellModel.tapTitleWithIndex = { value in
            self.titleLabelTappedWithIndex(value)
        }
        
        switchExpertMode.tapTitleWithIndex = { value in
            self.titleLabelTappedWithIndex(value)
        }
    }
    
    func onViewLoaded() {
        let quoteTokenAddress = chain.quoteTokenAddress()
        TokenService().getTokenDetail(address: quoteTokenAddress, chainPath: chain.apiChainPath()) { [weak self] tokenDetail in
            self?.quoteTokenDetail = tokenDetail
            self?.basicModeCellModel.updateQuoteToken(quoteToken: tokenDetail)
        }
    }
    
    func getBasicSettingInfo() -> BasicSettingsInfo {
        return (type: self.basicSelectedType, value: self.basicSelectedType.getGasValue())
    }
    
    func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
        if chain.isSupportedEIP1559() {
            return self.advancedModeCellModel.getAdvancedSettingInfo()
        } else {
            return basicAdvancedCellModel.getAdvancedSettingInfo()
        }
    }
    
    func getAdvancedNonce() -> Int {
        if chain.isSupportedEIP1559() {
            return advancedModeCellModel.customNonceValue
        } else {
            return basicAdvancedCellModel.customNonceValue
        }
    }
    
    func hasNoError() -> Bool {
        guard isAdvancedMode else {
            
            return slippageCellModel.hasNoError()
        }
        if chain.isSupportedEIP1559() {
            return advancedModeCellModel.hasNoError() && slippageCellModel.hasNoError()
        } else {
            return basicAdvancedCellModel.hasNoError() && slippageCellModel.hasNoError()
        }
    }
    
    func getAdvancedNonceString() -> String {
        if chain.isSupportedEIP1559() {
            return advancedModeCellModel.customNonceString
        } else {
            return basicAdvancedCellModel.nonceString
        }
    }
    
    func updateNonce(_ value: Int) {
        self.basicAdvancedCellModel.nonce = value
        self.advancedModeCellModel.nonce = value
        self.nonce = value
    }
    
    func resetData() {
        slippageCellModel.resetData()
        basicModeCellModel.resetData()
        basicAdvancedCellModel.resetData()
        advancedModeCellModel.resetData()
        segmentedCellModel.resetData()
        switchExpertMode.resetData()
        basicAdvancedCellModel.nonce = nonce
        advancedModeCellModel.nonce = nonce
    }
    
    func update(priorityFee: String?, maxGas: String?, gasLimit: String?, nonceString: String?) {
        if let notNil = priorityFee {
            advancedModeCellModel.maxPriorityFeeString = notNil
        }
        
        if let notNil = maxGas {
            basicAdvancedCellModel.gasPriceString = notNil
            advancedModeCellModel.maxFeeString = notNil
        }
        
        if let notNil = gasLimit {
            advancedModeCellModel.gasLimitString = notNil
            basicAdvancedCellModel.gasLimitString = notNil
        }
        
        if let notNil = nonceString, let nonceInt = Int(notNil) {
            nonce = nonceInt
            basicAdvancedCellModel.nonce = nonceInt
            advancedModeCellModel.nonce = nonceInt
        }
    }
    
    func buildSwapSetting() -> SwapTransactionSettings {
        let slippage = slippageCellModel.currentRate
        var basicSettings: BasicTransactionSettings? = nil
        var advancedSettings: AdvancedTransactionSettings? = nil
        if isAdvancedMode {
            let info = getAdvancedSettingInfo()
            let gasLimit = BigInt(info.gasLimit) ?? .zero
            let maxFee = info.maxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
            let maxPriorityFee = info.maxPriority.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
            let nonceInt = Int(getAdvancedNonce())
            advancedSettings = AdvancedTransactionSettings(gasLimit: gasLimit, maxFee: maxFee, maxPriorityFee: maxPriorityFee, nonce: nonceInt)
        } else {
            basicSettings = BasicTransactionSettings(gasPriceType: basicSelectedType)
        }
        
        return SwapTransactionSettings(slippage: slippage, basic: basicSettings, advanced: advancedSettings, expertModeOn: isExpertMode)
    }
    
    func saveWithBlock() {
        UserDefaults.standard.set(switchExpertMode.isOn, forKey: Constants.expertModeSaveKey)
        UserDefaults.standard.set(slippageCellModel.currentRate, forKey: Constants.slippageRateSaveKey)
        saveEventHandler(buildSwapSetting())
    }
}
