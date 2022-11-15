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

protocol UnstakeViewModelDelegate: class {
    func didGetDataSuccess()
    func didGetDataNeedApproveToken()
    func didGetDataFail(errMsg: String)
}

class UnstakeViewModel {
    let displayDepositedValue: String
    let ratio: BigInt
    let stakingTokenSymbol: String
    let toTokenSymbol: String
    let balance: BigInt
    let platform: Platform
    var unstakeValue: BigInt = BigInt(0) {
        didSet {
            self.configAllowance()
        }
    }
    let chain: ChainType
    var setting: TxSettingObject = .default
    let stakingTokenAddress: String
    let toUnderlyingTokenAddress: String
    var stakingTokenAllowance: BigInt = BigInt(0)
    
    weak var delegate: UnstakeViewModelDelegate?

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
    }
    
    func unstakeValueString() -> String {
        NumberFormatUtils.balanceFormat(value: unstakeValue, decimals: 18)
    }
    
    func receivedValue() -> BigInt {
        return unstakeValue * self.ratio / BigInt(10).power(18)
    }
    
    func receivedValueString() -> String {
        return NumberFormatUtils.balanceFormat(value: receivedValue(), decimals: 18) + " " + toTokenSymbol
    }
    
    func receivedValueMaxString() -> String {
        let maxValue = balance * self.ratio / BigInt(10).power(18)
        return NumberFormatUtils.balanceFormat(value: maxValue, decimals: 18)
    }
    
    func showRateInfo() -> String {
        let ratioString = NumberFormatUtils.balanceFormat(value: ratio, decimals: 18)
        return "1 \(stakingTokenSymbol) = \(ratioString) \(toTokenSymbol)"
    }
    
    func timeForUnstakeString() -> String {
        let isAnkr = platform.name.lowercased() == "ANKR".lowercased()
        let isLido = platform.name.lowercased() == "LIDO".lowercased()
        
        var time = ""
        if toTokenSymbol.lowercased() == "AVAX".lowercased() && isAnkr {
            time = "4 weeks"
        } else if toTokenSymbol.lowercased() == "BNB".lowercased() && isAnkr {
            time = "7-14 days"
        } else if toTokenSymbol.lowercased() == "FTM".lowercased() && isAnkr {
            time = "35 days"
        } else if toTokenSymbol.lowercased() == "MATIC".lowercased() && isAnkr {
            time = "3-4 days"
        } else if toTokenSymbol.lowercased() == "SOL".lowercased() && isLido {
            time = "2-3 days"
        }
        
        return "You will receive your \(toTokenSymbol) in \(time)"
    }
    
    func transactionFeeString() -> String {
        return NumberFormatUtils.gasFee(value: setting.transactionFee(chain: chain)) + " " + AppState.shared.currentChain.quoteToken()
    }
    
    func fetchData() {
        let service = EarnServices()
        service.getStakingOptionDetail(platform: platform.name, earningType: platform.type, chainID: "\(chain.getChainId())", tokenAddress: toUnderlyingTokenAddress) { result in
            switch result {
            case .success(let detail):
                if let earningToken = detail.earningTokens.first(where: { $0.address.lowercased() == self.stakingTokenAddress.lowercased() }) {
                    self.checkNeedApprove(earningToken: earningToken, contractAddress: detail.poolAddress)
                } else {
                    self.delegate?.didGetDataSuccess()
                }
            case .failure(let error):
                self.delegate?.didGetDataFail(errMsg: error.localizedDescription)
            }
        }
    }
    
    func checkNeedApprove(earningToken: EarningToken, contractAddress: String) {
        let service = EthereumNodeService(chain: chain)
        if earningToken.requireApprove {
            service.getAllowance(for: AppState.shared.currentAddress.addressString, networkAddress: contractAddress, tokenAddress: earningToken.address) { result in
                switch result {
                case .success(let number):
                    self.stakingTokenAllowance = number
                    self.configAllowance()
                case .failure(let error):
                    self.delegate?.didGetDataFail(errMsg: error.localizedDescription)
                }
            }
        } else {
            self.delegate?.didGetDataSuccess()
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
}
