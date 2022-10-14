//
//  SwapInfoViewModelProtocol.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 11/08/2022.
//

import Foundation
import BigInt
import Utilities
import Services
import BaseWallet
import AppState
import Dependencies

protocol SwapInfoViewModelProtocol {
    var settings: SwapTransactionSettings { get }
    var selectedRate: Rate? { get }
    var showRevertedRate: Bool { get }
}

extension SwapInfoViewModelProtocol {
    
    var isEIP1559: Bool {
        return AppState.shared.currentChain.isSupportedEIP1559()
    }
    
    var gasLimit: BigInt {
        if let advanced = settings.advanced {
            return advanced.gasLimit
        } else if let rate = selectedRate {
            return BigInt(rate.estimatedGas)
        } else {
            return AppDependencies.gasConfig.defaultExchangeGasLimit
        }
    }
    
    var gasPrice: BigInt {
        if let basic = settings.basic {
            if isEIP1559 {
                let baseFee = AppDependencies.gasConfig.baseFee
                let priorityFee = self.getPriorityFee(forType: basic.gasPriceType) ?? .zero
                return baseFee + priorityFee
            } else {
                return self.getGasPrice(forType: basic.gasPriceType)
            }
        } else if let advanced = settings.advanced {
            if isEIP1559 {
                return advanced.maxFee + advanced.maxPriorityFee
            } else {
                return advanced.maxFee
            }
        }
        return AppDependencies.gasConfig.standardGas
    }
    
    func getGasPrice(forType type: KNSelectedGasPriceType) -> BigInt {
        switch type {
        case .fast:
            return AppDependencies.gasConfig.fastGas
        case .medium:
            return AppDependencies.gasConfig.standardGas
        case .slow:
            return AppDependencies.gasConfig.lowGas
        case .superFast:
            return AppDependencies.gasConfig.superFastGas
        default: // No need to handle case .custom
            return AppDependencies.gasConfig.standardGas
        }
    }
    
    func getPriorityFee(forType type: KNSelectedGasPriceType) -> BigInt? {
        switch type {
        case .fast:
            return AppDependencies.gasConfig.fastPriorityFee
        case .medium:
            return AppDependencies.gasConfig.standardPriorityFee
        case .slow:
            return AppDependencies.gasConfig.lowPriorityFee
        case .superFast:
            return AppDependencies.gasConfig.superFastPriorityFee
        default: // No need to handle case .custom
            return AppDependencies.gasConfig.standardPriorityFee
        }
    }
    
    func getPriceImpactString(rate: Rate) -> String {
        let change = Double(rate.priceImpact) / 10000
        return StringFormatter.percentString(value: change)
    }
    
    func getMinReceiveString(destToken: Token, rate: Rate) -> String {
        let amount = BigInt(rate.amount) ?? BigInt(0)
        let minReceivingAmount = amount * BigInt(10000.0 - settings.slippage * 100.0) / BigInt(10000.0)
        return "\(NumberFormatUtils.amount(value: minReceivingAmount, decimals: destToken.decimals)) \(destToken.symbol)"
    }
    
    func getEstimatedNetworkFeeString(rate: Rate) -> String {
        let feeInUSD = self.getGasFeeUSD(estGas: BigInt(rate.estGasConsumed ?? 0), gasPrice: self.gasPrice)
        if let basic = settings.basic {
            let typeString: String = {
                switch basic.gasPriceType {
                case .superFast:
                    return Strings.superFast
                case .fast:
                    return Strings.fast
                case .medium:
                    return Strings.standard
                case .slow:
                    return Strings.slow
                case .custom:
                    return Strings.custom
                }
            }()
            return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18)) • \(typeString)"
        }
        let typeString = Strings.custom
        return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18)) • \(typeString)"
    }
    
    func getMaxNetworkFeeString(rate: Rate) -> String {
        if let basic = settings.basic {
            let feeInUSD = self.getGasFeeUSD(estGas: gasLimit, gasPrice: self.getGasPrice(forType: basic.gasPriceType))
            return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18))"
        } else if let advanced = settings.advanced {
            let feeInUSD = self.getGasFeeUSD(estGas: gasLimit, gasPrice: advanced.maxFee)
            return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18))"
        }
        return ""
    }
    
    func getGasFeeUSD(estGas: BigInt, gasPrice: BigInt) -> BigInt {
        let quoteToken = AppDependencies.tokenStorage.quoteToken(forChain: AppState.shared.currentChain)
        let decimals = quoteToken.decimals
        let rateUSDDouble = AppDependencies.priceStorage.price(tokenAddress: quoteToken.address, chain: AppState.shared.currentChain)?.usd ?? 0
        let rateBigInt = BigInt(rateUSDDouble * pow(10.0, Double(decimals)))
        let feeUSD = (estGas * gasPrice * rateBigInt) / BigInt(10).power(decimals)
        return feeUSD
    }
    
    func getPriceImpactState(change: Double) -> PriceImpactState {
        let isExpertModeOn = UserDefaults.standard.bool(forKey: Constants.expertModeSaveKey)
        if change < -100 {
            return isExpertModeOn ? .veryHigh : .outOfNegativeRange
        }
        if -100 <= change && change <= -15 {
            return isExpertModeOn ? .veryHigh : .veryHighNeedExpertMode
        }
        if -15 < change && change <= -5 {
            return .high
        }
        if -5 < change && change <= 100 {
            return .normal
        }
        return .outOfPositiveRange
    }
    
    func getRateString(sourceToken: Token, destToken: Token) -> String? {
        guard let selectedPlatform = selectedRate else {
            return nil
        }
        if showRevertedRate {
            let rate = BigInt(selectedPlatform.rate) ?? .zero
            let revertedRate = rate.isZero ? 0 : (BigInt(10).power(36) / rate)
            let rateString = NumberFormatUtils.rate(value: revertedRate, decimals: 18)
            return "1 \(destToken.symbol) = \(rateString) \(sourceToken.symbol)"
        } else {
            let rateString = NumberFormatUtils.rate(value: BigInt(selectedPlatform.rate) ?? .zero, decimals: 18)
            return "1 \(sourceToken.symbol) = \(rateString) \(destToken.symbol)"
        }
    }
    
    func diffInUSD(lhs: Rate, rhs: Rate, destToken: Token, destTokenPrice: Double) -> BigInt {
        let diffAmount = (BigInt(lhs.amount) ?? BigInt(0)) - (BigInt(rhs.amount) ?? BigInt(0))
        let diffFee = BigInt(lhs.estimatedGas) - BigInt(rhs.estimatedGas)
        let diffAmountUSD = diffAmount * BigInt(destTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(destToken.decimals)
        let diffFeeUSD = self.getGasFeeUSD(estGas: diffFee, gasPrice: self.gasPrice)
        return diffAmountUSD - diffFeeUSD
    }
    
}
