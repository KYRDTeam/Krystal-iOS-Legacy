//
//  UnstakeViewModel.swift
//  EarnModule
//
//  Created by Com1 on 14/11/2022.
//

import UIKit
import Services
import BigInt
import Utilities
import TransactionModule
import AppState
import Dependencies
import BaseModule

protocol UnstakeViewModelDelegate: class {
    func didGetDataSuccess()
    func didGetDataNeedApproveToken()
    func didGetDataFail(errMsg: String)
    func didCheckNotEnoughFeeForTx(errMsg: String)
    func didApproveToken(success: Bool)
    func didGetWrapInfo(wrap: WrapInfo)
}

class UnstakeViewModel: BaseViewModel {
    let displayDepositedValue: String
    let ratio: BigInt
    let stakingTokenSymbol: String
    var toTokenSymbol: String
    let balance: BigInt
    let platform: Platform
    var unstakeValue: BigInt = BigInt(0) {
        didSet {
            self.requestBuildUnstakeTx()
            self.configAllowance()
            self.checkEnoughFeeForTx()
        }
    }
    let chain: ChainType
    let earningType: EarningType
    var setting: TxSettingObject = .default
    let stakingTokenAddress: String
    let stakingTokenLogo: String
    let toTokenLogo: String
    let stakingTokenDecimal: Int
    var toUnderlyingTokenAddress: String
    var stakingTokenAllowance: BigInt = BigInt(0)
    var contractAddress: String?
    var minUnstakeAmount: BigInt = BigInt(0)
    var maxUnstakeAmount: BigInt = BigInt(0)
    var showRevertedRate: Bool = false
    var quoteTokenDetail: TokenDetailInfo?
    weak var delegate: UnstakeViewModelDelegate?
    var approveHash: String?
    var wrapInfo: WrapInfo?
    let apiService = EarnServices()
    
    var isLido: Bool {
        return platform.name.lowercased() == "LIDO".lowercased()
    }
    
    var isAnkr: Bool {
        return platform.name.lowercased() == "ANKR".lowercased()
    }
    var buildTxRequestParams: JSONDictionary {
        
        var earningType: String = platform.type
        if toTokenSymbol.lowercased() == "MATIC".lowercased() && ( isLido || isAnkr ) {
            earningType = "stakingMATIC"
        }
        var params: JSONDictionary = [
            "tokenAmount": unstakeValue.description,
            "chainID": chain.getChainId(),
            "earningType": earningType,
            "platform": platform.name,
            "userAddress": AppState.shared.currentAddress.addressString,
            "tokenAddress": toUnderlyingTokenAddress
        ]
        if platform.name.lowercased() == "ankr" {
            var useC = false
            if stakingTokenSymbol.suffix(1).description.lowercased() == "c" {
                useC = true
            }
            
            params["extraData"] = ["ankr": ["useTokenC": useC]]
        }
        return params
    }
    var quoteTokenUsdPrice: Double {
        return quoteTokenDetail?.markets["usd"]?.price ?? 0
    }
    var feeUSDString: String {
        let usd = setting.transactionFee(chain: chain) * BigInt(quoteTokenUsdPrice * pow(10, 18)) / BigInt(10).power(18)
        let valueString = NumberFormatUtils.gasFee(value: usd)
        return " (~ $\(valueString))"
    }
    var txObject: TxObject?
    var onGasSettingUpdated: (() -> ())?
    var onFetchedQuoteTokenPrice: (() -> ())?
    
    var platformTitleString: String {
        switch earningType {
        case .staking:
            return Strings.unstake + " " + stakingTokenSymbol + " on " + platform.name.uppercased()
        case .lending:
            return Strings.withdraw + " " + stakingTokenSymbol + " on " + platform.name.uppercased()
        }
    }
    
    var availableBalanceTitleString: String {
        switch earningType {
        case .staking:
            return Strings.availableToUnstake
        case .lending:
            return Strings.availableToWithdraw
        }
    }
    
    var buttonTitleString: String {
        switch earningType {
        case .staking:
            return Strings.unstake + " " + stakingTokenSymbol
        case .lending:
            return Strings.withdraw + " " + stakingTokenSymbol
        }
    }

    init(earningBalance: EarningBalance) {
        self.displayDepositedValue = (BigInt(earningBalance.stakingToken.balance)?.shortString(decimals: earningBalance.stakingToken.decimals) ?? "---") + " " + earningBalance.stakingToken.symbol
        self.ratio = BigInt(earningBalance.ratio)
        self.stakingTokenSymbol = earningBalance.stakingToken.symbol
        self.toTokenSymbol = earningBalance.toUnderlyingToken.symbol
        self.balance = BigInt(earningBalance.stakingToken.balance) ?? BigInt(0)
        self.platform = earningBalance.platform
        self.chain = ChainType.make(chainID: earningBalance.chainID) ?? AppState.shared.currentChain
        self.toUnderlyingTokenAddress = earningBalance.toUnderlyingToken.address
        self.stakingTokenAddress = earningBalance.stakingToken.address
        self.stakingTokenDecimal = earningBalance.stakingToken.decimals
        self.stakingTokenLogo = earningBalance.stakingToken.logo
        self.toTokenLogo = earningBalance.toUnderlyingToken.logo
        self.earningType = EarningType(value: earningBalance.platform.type)
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: .kTxStatusUpdated, object: nil)
    }
    
    func observeEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.txStatusUpdated(_:)),
            name: .kTxStatusUpdated,
            object: nil
        )
    }
    
    @objc func txStatusUpdated(_ notification: Notification) {
        guard let hash = notification.userInfo?["hash"] as? String, let status = notification.userInfo?["status"] as? InternalTransactionState else {
            return
        }
        guard let approveHash = approveHash, approveHash == hash else {
            return
        }
        
        switch status {
        case .error, .drop:
            self.delegate?.didApproveToken(success: false)
        case .done:
            self.delegate?.didApproveToken(success: true)
        default:
            print(status)
        }
    }
    
    func unstakeValueString() -> String {
        NumberFormatUtils.balanceFormat(value: unstakeValue, decimals: stakingTokenDecimal)
    }
    
    func receivedValue() -> BigInt {
        return unstakeValue * self.ratio / BigInt(10).power(18)
    }
    
    func receivedValueString() -> String {
        return NumberFormatUtils.balanceFormat(value: receivedValue(), decimals: stakingTokenDecimal)
    }
    
    func receivedInfoString() -> String {
        return receivedValueString() + " " + toTokenSymbol
    }
    
    func receivedValueMaxString() -> String {
        let maxValue = balance * self.ratio / BigInt(10).power(18)
        return NumberFormatUtils.balanceFormat(value: maxValue, decimals: stakingTokenDecimal)
    }
    
    func showRateInfo() -> String {
        if showRevertedRate {
            let ratioString = NumberFormatUtils.balanceFormat(value: BigInt(10).power(36) / ratio, decimals: 18)
            return "1 \(toTokenSymbol) = \(ratioString) \(stakingTokenSymbol)"
        } else {
            let ratioString = NumberFormatUtils.balanceFormat(value: ratio, decimals: 18)
            return "1 \(stakingTokenSymbol) = \(ratioString) \(toTokenSymbol)"
        }
    }
    
    func checkEnoughFeeForTx() {
        let fee = setting.transactionFee(chain: chain)
        let nodeService = EthereumNodeService(chain: chain)
        nodeService.getQuoteBalanace(address: currentAddress.addressString) { result in
            switch result {
            case .success(let balance):
                if balance.value < fee {
                    self.delegate?.didCheckNotEnoughFeeForTx(errMsg: "")
                }
            case .failure(let err):
                self.delegate?.didCheckNotEnoughFeeForTx(errMsg: err.localizedDescription)
            }
        }
    }

    func timeForUnstakeString() -> String {
        var time = ""
        if toTokenSymbol.lowercased() == "AVAX".lowercased() && isAnkr {
            time = Strings.avaxUnstakeTime
        } else if toTokenSymbol.lowercased() == "BNB".lowercased() && isAnkr {
            time = Strings.bnbUnstakeTime
        } else if toTokenSymbol.lowercased() == "FTM".lowercased() && isAnkr {
            time = Strings.ftmUnstakeTime
        } else if toTokenSymbol.lowercased() == "MATIC".lowercased() && isAnkr {
            time = Strings.maticUnstakeTime
        } else if toTokenSymbol.lowercased() == "SOL".lowercased() && isLido {
            time =  Strings.solUnstakeTime
        }
        if time.isEmpty {
            return ""
        }
        return String(format: Strings.youWillReceiveYourIn, toTokenSymbol, time)
    }

    func transactionFeeString() -> String {
        return NumberFormatUtils.gasFee(value: setting.transactionFee(chain: chain)) + " " + AppState.shared.currentChain.quoteToken() + feeUSDString
    }
    
    func updateWrapInfo(isUseWrap: Bool) {
        if isUseWrap && toTokenSymbol.first?.uppercased() == "W" {
            toTokenSymbol.removeFirst()
        } else {
            toTokenSymbol = "W" + toTokenSymbol
        }
        
        if let wrapInfo = wrapInfo {
            toUnderlyingTokenAddress = wrapInfo.wrapAddress
        }
        requestBuildUnstakeTx()
    }
    
    func fetchData(isUseWrapTokenAddress: Bool = false, completion: @escaping () -> ()) {
        var tokenAddress = toUnderlyingTokenAddress
        if isUseWrapTokenAddress {
            if let wrapInfo = wrapInfo {
                tokenAddress = wrapInfo.wrapAddress
            }
        }
        
        
        apiService.getStakingOptionDetail(platform: platform.name, earningType: platform.type, chainID: "\(chain.getChainId())", tokenAddress: tokenAddress) { result in
            switch result {
            case .success(let detail):
                if let earningToken = detail.earningTokens.first(where: { $0.address.lowercased() == self.stakingTokenAddress.lowercased() }) {
                    self.contractAddress = detail.poolAddress
                    if let wrap = detail.wrap {
                        self.wrapInfo = wrap
                        self.delegate?.didGetWrapInfo(wrap: wrap)
                    }
                    
                    let minAmount = detail.validation?.minUnstakeAmount ?? 0
                    self.minUnstakeAmount = BigInt(minAmount * pow(10.0, Double(self.stakingTokenDecimal)))
                    let maxAmount = detail.validation?.maxUnstakeAmount ?? 0
                    self.maxUnstakeAmount = BigInt(maxAmount * pow(10.0, Double(self.stakingTokenDecimal)))
                    self.checkNeedApprove(earningToken: earningToken, completion: completion)
                } else {
                    completion()
                    self.delegate?.didGetDataSuccess()
                }
            case .failure(let error):
                completion()
                self.delegate?.didGetDataFail(errMsg: error.localizedDescription)
            }
        }
    }
    
    func checkNeedApprove(earningToken: EarningToken, completion: @escaping () -> ()) {
        guard let contractAddress = contractAddress else { return }
        let service = EthereumNodeService(chain: chain)
        if earningToken.requireApprove {
            service.getAllowance(for: AppState.shared.currentAddress.addressString, networkAddress: contractAddress, tokenAddress: earningToken.address) { result in
                completion()
                switch result {
                case .success(let number):
                    self.stakingTokenAllowance = number
                    self.configAllowance()
                case .failure(let error):
                    self.delegate?.didGetDataFail(errMsg: error.localizedDescription)
                }
            }
        } else {
            completion()
            self.stakingTokenAllowance = TransactionConstants.maxTokenAmount
            self.delegate?.didGetDataSuccess()
        }
    }
    
    func requestBuildUnstakeTx(showLoading: Bool = false, completion: @escaping ((Error?) -> Void) = {_ in }) {
        apiService.buildUnstakeTx(param: buildTxRequestParams) { [weak self] result in
            switch result {
            case .success(let tx):
                self?.txObject = tx
                if let gasLimit = BigInt(tx.gasLimit.drop0x, radix: 16), gasLimit > 0 {
                    self?.didGetTxGasLimit(gasLimit: gasLimit)
                }
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func configAllowance() {
        if stakingTokenAllowance < unstakeValue {
            //need approve more
            self.delegate?.didGetDataNeedApproveToken()
        } else {
            // can make transaction
            self.delegate?.didGetDataSuccess()
        }
    }
    
    func didGetTxGasLimit(gasLimit: BigInt) {
        if setting.advanced != nil {
            return
        }
        setting.basic?.gasLimit = gasLimit
        onGasSettingUpdated?()
        checkEnoughFeeForTx()
    }
}

extension UnstakeViewModel {
    func getQuoteTokenPrice() {
        let tokenService = TokenService()
        tokenService.getTokenDetail(address: currentChain.customRPC().quoteTokenAddress, chainPath: currentChain.customRPC().apiChainPath) { [weak self] tokenDetail in
            self?.quoteTokenDetail = tokenDetail
            self?.onFetchedQuoteTokenPrice?()
        }
    }
}
